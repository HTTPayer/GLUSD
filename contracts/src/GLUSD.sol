// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title GLUSD - Galaksio USD
/// @notice Reward-accruing stablecoin backed by USDC
/// @dev Non-rebasing ERC20 where value accrues through exchange rate appreciation
/// - Backed by USDC held in this contract
/// - Mint: deposit USDC -> mint GLUSD at current exchange rate
/// - Redeem: burn GLUSD -> receive USDC at current exchange rate
/// - Treasury deposits fees which increase the exchange rate for all holders
/// - Onchain rate snapshots for APR/APY calculations
/// - Pausable for emergency stops
/// - 0.5% fee on mint/redeem sent to feeRecipient (configurable)
/// - Alpha version: capped at MAX_TOTAL_SUPPLY for risk management
contract GLUSD is ERC20, Pausable, ReentrancyGuard {
    address public admin;
    address public pauser;
    address public feeRecipient;

    mapping(address => bool) public isTreasury;

    uint256 public constant FEE_BP = 50; // 0.5% fee on mint/redeem
    uint256 public constant BP_SCALE = 10_000; // Basis points scale

    /// @notice Maximum total supply for alpha launch (1k GLUSD with 6 decimals)
    /// @dev This limit protects against excessive exposure during the alpha phase
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000e6; // 1,000 GLUSD

    /// @notice Seconds in a year for APR/APY calculations
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    IERC20 public immutable USDC;
    uint8 private immutable _decimals;

    /// @notice Snapshot of exchange rate at a specific time
    struct RateSnapshot {
        uint256 rate;       // Exchange rate (USDC per GLUSD, scaled by 1e6)
        uint256 timestamp;  // Block timestamp of snapshot
    }

    /// @notice Circular buffer of recent rate snapshots (max 90 days at 1 snapshot/hour)
    /// @dev We keep ~2160 snapshots (90 days * 24 hours) for onchain APR/APY calculations
    /// Full history can be reconstructed from RateSnapshotTaken events
    RateSnapshot[2160] public recentSnapshots;

    /// @notice Current index in the circular buffer
    uint256 public snapshotIndex;

    /// @notice Total number of snapshots taken (never decreases)
    uint256 public totalSnapshotCount;

    /// @notice Timestamp of last snapshot taken
    uint256 public lastSnapshotTime;

    /// @notice Minimum time between snapshots (30 seconds)
    uint256 public constant MIN_SNAPSHOT_INTERVAL = 30 seconds;

    /// @notice Maximum snapshots stored in circular buffer
    uint256 public constant MAX_SNAPSHOTS = 2160;

    event Mint(address indexed user, uint256 usdcDeposited, uint256 glusdMinted, uint256 fee);
    event Redeem(address indexed user, uint256 glusdBurned, uint256 usdcReturned, uint256 fee);
    event FeesDeposited(address indexed depositor, uint256 amount);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event PauserUpdated(address indexed oldPauser, address indexed newPauser);
    event RateSnapshotTaken(uint256 rate, uint256 timestamp);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    /// @notice Constructs the GLUSD contract
    /// @param _usdc Address of the USDC token contract
    /// @param _treasury Address to be set as treasury
    constructor(IERC20 _usdc, address _treasury, address _feeRecipient) ERC20("Galaksio USD", "GLUSD") {
        require(address(_usdc) != address(0), "GLUSD: zero USDC address");
        require(_treasury != address(0), "GLUSD: zero treasury address");
        require(_feeRecipient != address(0), "GLUSD: zero fee recipient address");

        USDC = _usdc;
        _decimals = 6; // Match USDC decimals

        // Set addresses
        admin = msg.sender;
        isTreasury[_treasury] = true;

        pauser = msg.sender;
        feeRecipient = _feeRecipient;

        // Take initial snapshot at 1:1 rate in circular buffer
        recentSnapshots[0] = RateSnapshot({
            rate: 1e6,
            timestamp: block.timestamp
        });
        snapshotIndex = 0;
        totalSnapshotCount = 1;
        lastSnapshotTime = block.timestamp;

        emit TreasuryUpdated(address(0), _treasury);
        emit RateSnapshotTaken(1e6, block.timestamp);
    }

    /// @notice Returns the number of decimals (6 to match USDC)
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function addTreasury(address t) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(t != address(0), "GLUSD: zero address");
        isTreasury[t] = true;
        emit TreasuryUpdated(address(0), t); // old=0 means "added"
    }

    function removeTreasury(address t) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(isTreasury[t], "GLUSD: not a treasury");
        isTreasury[t] = false;
        emit TreasuryUpdated(t, address(0)); // new=0 means "removed"
    }

    /// @notice Calculates the current exchange rate (USDC per GLUSD)
    /// @dev Returns the amount of USDC per 1 GLUSD token (scaled by 1e6)
    /// @return rate Exchange rate scaled by 1e6 (6 decimals)
    function exchangeRate() public view returns (uint256 rate) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return 1e6; // 1:1 when no supply exists
        }
        uint256 usdcBalance = USDC.balanceOf(address(this));
        // rate = (usdcBalance * 1e6) / supply
        // This gives us USDC per GLUSD in 6 decimal precision
        rate = (usdcBalance * 1e6) / supply;
    }

    /// @notice Mint GLUSD by depositing USDC at the current exchange rate
    /// @dev User must approve USDC to this contract before calling. 0.5% fee is deducted.
    /// @param usdcAmount Amount of USDC to deposit (including fee)
    /// @return glusdMinted Amount of GLUSD minted
    function mint(uint256 usdcAmount)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 glusdMinted)
    {
        require(usdcAmount > 0, "GLUSD: zero amount");

        // Calculate fee and amount after fee
        uint256 fee = (usdcAmount * FEE_BP) / BP_SCALE;
        uint256 amountAfterFee = usdcAmount - fee;

        // Transfer fee to feeRecipient
        bool feeSuccess = USDC.transferFrom(msg.sender, feeRecipient, fee);
        require(feeSuccess, "GLUSD: fee transfer failed");

        // Transfer USDC after fee to vault
        bool success = USDC.transferFrom(msg.sender, address(this), amountAfterFee);
        require(success, "GLUSD: USDC transfer failed");

        // Calculate GLUSD to mint based on amountAfterFee at current exchange rate
        // If totalSupply is 0, mint 1:1 with amountAfterFee
        // Otherwise: glusdMinted = (amountAfterFee * 1e6) / exchangeRate()
        uint256 supply = totalSupply();
        if (supply == 0) {
            glusdMinted = amountAfterFee;
        } else {
            uint256 rate = exchangeRate();
            require(rate > 0, "GLUSD: invalid exchange rate");
            // glusdMinted = (amountAfterFee * 1e6) / rate
            glusdMinted = (amountAfterFee * 1e6) / rate;
        }

        require(glusdMinted > 0, "GLUSD: mint amount too small");

        // Alpha launch cap: prevent minting beyond max supply
        uint256 newTotalSupply = supply + glusdMinted;
        require(newTotalSupply <= MAX_TOTAL_SUPPLY, "GLUSD: exceeds max supply cap");

        _mint(msg.sender, glusdMinted);
        emit Mint(msg.sender, usdcAmount, glusdMinted, fee);
    }

    /// @notice Redeem GLUSD for USDC at the current exchange rate
    /// @dev 0.5% fee is deducted from USDC returned
    /// @param glusdAmount Amount of GLUSD to burn
    /// @return usdcOut Amount of USDC returned (after fee)
    function redeem(uint256 glusdAmount)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 usdcOut)
    {
        require(glusdAmount > 0, "GLUSD: zero amount");
        require(totalSupply() > 0, "GLUSD: no supply");
        require(balanceOf(msg.sender) >= glusdAmount, "GLUSD: insufficient balance");

        // Calculate USDC to return based on current exchange rate (before fee)
        // usdcGross = (glusdAmount * exchangeRate()) / 1e6
        uint256 rate = exchangeRate();
        uint256 usdcGross = (glusdAmount * rate) / 1e6;
        require(usdcGross > 0, "GLUSD: redeem amount too small");

        // Calculate fee and amount after fee
        uint256 fee = (usdcGross * FEE_BP) / BP_SCALE;
        usdcOut = usdcGross - fee;

        uint256 usdcBalance = USDC.balanceOf(address(this));
        require(usdcGross <= usdcBalance, "GLUSD: insufficient USDC reserves");

        // Burn GLUSD first (checks-effects-interactions pattern)
        _burn(msg.sender, glusdAmount);

        // Transfer fee to feeRecipient
        bool feeSuccess = USDC.transfer(feeRecipient, fee);
        require(feeSuccess, "GLUSD: fee transfer failed");

        // Transfer USDC after fee to user
        bool success = USDC.transfer(msg.sender, usdcOut);
        require(success, "GLUSD: USDC transfer failed");

        emit Redeem(msg.sender, glusdAmount, usdcOut, fee);
    }

    /// @notice Deposit fees into the vault (increases exchange rate for all holders)
    /// @dev Only callable by treasury. Automatically takes rate snapshot if interval has passed.
    /// @param amount Amount of USDC to deposit as fees
    function depositFees(uint256 amount)
        external
        nonReentrant
        returns (bool)
    {
        require(isTreasury[msg.sender], "GLUSD: only treasury");

        require(amount > 0, "GLUSD: zero amount");

        bool success = USDC.transferFrom(msg.sender, address(this), amount);
        require(success, "GLUSD: USDC transfer failed");

        emit FeesDeposited(msg.sender, amount);

        // Take a rate snapshot after fee deposit if enough time has passed
        _takeSnapshotIfNeeded();

        return true;
    }

    /// @notice Manually take a rate snapshot (callable by anyone if interval has passed)
    /// @dev Useful for updating yield calculations without depositing fees
    function takeSnapshot() external {
        _takeSnapshotIfNeeded();
    }

    /// @notice Internal function to take a rate snapshot if minimum interval has passed
    function _takeSnapshotIfNeeded() internal {
        // Only take snapshot if enough time has passed and supply exists
        if (block.timestamp >= lastSnapshotTime + MIN_SNAPSHOT_INTERVAL && totalSupply() > 0) {
            uint256 currentRate = exchangeRate();

            // Increment index in circular buffer (wraps around at MAX_SNAPSHOTS)
            snapshotIndex = (snapshotIndex + 1) % MAX_SNAPSHOTS;

            // Store snapshot in circular buffer
            recentSnapshots[snapshotIndex] = RateSnapshot({
                rate: currentRate,
                timestamp: block.timestamp
            });

            totalSnapshotCount++;
            lastSnapshotTime = block.timestamp;
            emit RateSnapshotTaken(currentRate, block.timestamp);
        }
    }

    /// @notice Returns current USDC balance and GLUSD supply
    /// @return usdcBalance Current USDC held by contract
    /// @return supply Current GLUSD total supply
    function vaultStatus() external view returns (uint256 usdcBalance, uint256 supply) {
        usdcBalance = USDC.balanceOf(address(this));
        supply = totalSupply();
    }

    /// @notice Returns remaining mintable supply for alpha cap
    /// @return remaining Amount of GLUSD that can still be minted
    function remainingMintableSupply() external view returns (uint256 remaining) {
        uint256 supply = totalSupply();
        if (supply >= MAX_TOTAL_SUPPLY) {
            return 0;
        }
        return MAX_TOTAL_SUPPLY - supply;
    }

    /// @notice Get the number of rate snapshots currently stored in buffer
    /// @return count Number of snapshots available (max 2160, or totalSnapshotCount if less)
    function getSnapshotCount() external view returns (uint256 count) {
        return totalSnapshotCount > MAX_SNAPSHOTS ? MAX_SNAPSHOTS : totalSnapshotCount;
    }

    /// @notice Get the most recent snapshot
    /// @return rate Exchange rate at the most recent snapshot
    /// @return timestamp Time of the most recent snapshot
    function getMostRecentSnapshot() external view returns (uint256 rate, uint256 timestamp) {
        RateSnapshot memory snapshot = recentSnapshots[snapshotIndex];
        return (snapshot.rate, snapshot.timestamp);
    }

    /// @notice Get a snapshot from N snapshots ago (0 = most recent)
    /// @param snapshotsAgo How many snapshots back to retrieve (0 to 2159)
    /// @return rate Exchange rate at that snapshot
    /// @return timestamp Time of the snapshot
    function getSnapshotFromPast(uint256 snapshotsAgo) external view returns (uint256 rate, uint256 timestamp) {
        uint256 available = totalSnapshotCount > MAX_SNAPSHOTS ? MAX_SNAPSHOTS : totalSnapshotCount;
        require(snapshotsAgo < available, "GLUSD: snapshot too old");

        // Calculate the circular buffer index
        uint256 targetIndex;
        if (snapshotsAgo <= snapshotIndex) {
            targetIndex = snapshotIndex - snapshotsAgo;
        } else {
            targetIndex = MAX_SNAPSHOTS - (snapshotsAgo - snapshotIndex);
        }

        RateSnapshot memory snapshot = recentSnapshots[targetIndex];
        return (snapshot.rate, snapshot.timestamp);
    }

    /// @notice Calculate APR based on rate change over a time period
    /// @param daysAgo Number of days ago to compare against (e.g., 7 for 7-day APR, max 90)
    /// @return apr Annual Percentage Rate scaled by 1e6 (e.g., 5% = 5e6)
    function calculateAPR(uint256 daysAgo) external view returns (uint256 apr) {
        require(daysAgo > 0, "GLUSD: invalid days");
        require(daysAgo <= 90, "GLUSD: max 90 days");
        require(totalSnapshotCount > 0, "GLUSD: no history");

        uint256 currentRate = exchangeRate();
        uint256 targetTimestamp = block.timestamp - (daysAgo * 1 days);

        // Find the snapshot closest to targetTimestamp in circular buffer
        uint256 oldRate;
        uint256 oldTimestamp;
        bool foundSnapshot = false;

        uint256 availableSnapshots = totalSnapshotCount > MAX_SNAPSHOTS ? MAX_SNAPSHOTS : totalSnapshotCount;

        // Search backwards through circular buffer
        for (uint256 i = 0; i < availableSnapshots; i++) {
            uint256 bufferIndex;
            if (i <= snapshotIndex) {
                bufferIndex = snapshotIndex - i;
            } else {
                bufferIndex = MAX_SNAPSHOTS - (i - snapshotIndex);
            }

            RateSnapshot memory snapshot = recentSnapshots[bufferIndex];
            if (snapshot.timestamp <= targetTimestamp) {
                oldRate = snapshot.rate;
                oldTimestamp = snapshot.timestamp;
                foundSnapshot = true;
                break;
            }
        }

        // If no snapshot old enough, use the oldest available
        if (!foundSnapshot) {
            uint256 oldestIndex;
            if (totalSnapshotCount > MAX_SNAPSHOTS) {
                // Buffer is full, oldest is next after current
                oldestIndex = (snapshotIndex + 1) % MAX_SNAPSHOTS;
            } else {
                // Buffer not full, oldest is at index 0
                oldestIndex = 0;
            }
            RateSnapshot memory oldestSnapshot = recentSnapshots[oldestIndex];
            oldRate = oldestSnapshot.rate;
            oldTimestamp = oldestSnapshot.timestamp;
        }

        uint256 timeElapsed = block.timestamp - oldTimestamp;
        if (timeElapsed == 0 || oldRate == 0) {
            return 0;
        }

        // Calculate rate change: (currentRate - oldRate) / oldRate
        // APR = (rateChange / timeElapsed) * SECONDS_PER_YEAR * 100
        // Scaled by 1e6 for percentage with 6 decimals
        if (currentRate <= oldRate) {
            return 0; // No yield or negative yield
        }

        uint256 rateIncrease = currentRate - oldRate;
        // apr = (rateIncrease * SECONDS_PER_YEAR * 1e8) / (oldRate * timeElapsed)
        // The 1e8 comes from: 1e6 (percentage scale) * 100 (for %) = 1e8
        apr = (rateIncrease * SECONDS_PER_YEAR * 1e8) / (oldRate * timeElapsed);
    }

    /// @notice Calculate APY (compound annual yield) based on rate change
    /// @param daysAgo Number of days ago to compare against (max 90)
    /// @return apy Annual Percentage Yield scaled by 1e6 (e.g., 5% = 5e6)
    /// @dev APY = ((1 + periodicRate)^periods - 1) * 100, approximated for small rates
    function calculateAPY(uint256 daysAgo) external view returns (uint256 apy) {
        require(daysAgo > 0, "GLUSD: invalid days");
        require(daysAgo <= 90, "GLUSD: max 90 days");
        require(totalSnapshotCount > 0, "GLUSD: no history");

        uint256 currentRate = exchangeRate();
        uint256 targetTimestamp = block.timestamp - (daysAgo * 1 days);

        // Find the snapshot closest to targetTimestamp
        uint256 oldRate;
        uint256 oldTimestamp;
        bool foundSnapshot = false;

        uint256 availableSnapshots = totalSnapshotCount > MAX_SNAPSHOTS ? MAX_SNAPSHOTS : totalSnapshotCount;

        for (uint256 i = 0; i < availableSnapshots; i++) {
            uint256 bufferIndex;
            if (i <= snapshotIndex) {
                bufferIndex = snapshotIndex - i;
            } else {
                bufferIndex = MAX_SNAPSHOTS - (i - snapshotIndex);
            }

            RateSnapshot memory snapshot = recentSnapshots[bufferIndex];
            if (snapshot.timestamp <= targetTimestamp) {
                oldRate = snapshot.rate;
                oldTimestamp = snapshot.timestamp;
                foundSnapshot = true;
                break;
            }
        }

        if (!foundSnapshot) {
            uint256 oldestIndex;
            if (totalSnapshotCount > MAX_SNAPSHOTS) {
                oldestIndex = (snapshotIndex + 1) % MAX_SNAPSHOTS;
            } else {
                oldestIndex = 0;
            }
            RateSnapshot memory oldestSnapshot = recentSnapshots[oldestIndex];
            oldRate = oldestSnapshot.rate;
            oldTimestamp = oldestSnapshot.timestamp;
        }

        uint256 timeElapsed = block.timestamp - oldTimestamp;
        if (timeElapsed == 0 || oldRate == 0 || currentRate <= oldRate) {
            return 0;
        }

        // For small yields, APY ≈ APR * (1 + APR/2) ≈ APR for simplicity
        // More accurate: calculate (currentRate/oldRate)^(SECONDS_PER_YEAR/timeElapsed) - 1
        // Simplified: just use the ratio and annualize
        uint256 rateRatio = (currentRate * 1e18) / oldRate; // Scale up for precision
        uint256 periodsPerYear = SECONDS_PER_YEAR / timeElapsed;

        // For small returns: APY ≈ ((rateRatio - 1e18) * periodsPerYear * 100) / 1e18
        // Scaled to 1e6 for percentage
        if (rateRatio <= 1e18) {
            return 0;
        }

        uint256 growth = rateRatio - 1e18;
        apy = (growth * periodsPerYear * 1e8) / 1e18; // 1e8 = 1e6 * 100 for percentage
    }

    /// @notice Get current 7-day and 30-day APR for easy access
    /// @return apr7d 7-day APR scaled by 1e6
    /// @return apr30d 30-day APR scaled by 1e6
    function getCurrentAPRs() external view returns (uint256 apr7d, uint256 apr30d) {
        if (totalSnapshotCount == 0) {
            return (0, 0);
        }

        // Try to calculate 7-day APR
        try this.calculateAPR(7) returns (uint256 apr7) {
            apr7d = apr7;
        } catch {
            apr7d = 0;
        }

        // Try to calculate 30-day APR
        try this.calculateAPR(30) returns (uint256 apr30) {
            apr30d = apr30;
        } catch {
            apr30d = 0;
        }
    }

    /// @notice Pause contract (stops minting and redemption)
    /// @dev Only callable by pauser
    function pause() external {
        require(msg.sender == pauser, "GLUSD: only pauser");
        _pause();
    }

    /// @notice Unpause contract
    /// @dev Only callable by pauser
    function unpause() external {
        require(msg.sender == pauser, "GLUSD: only pauser");
        _unpause();
    }

    function setFeeRecipient(address newRecipient) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(newRecipient != address(0), "GLUSD: zero recipient");
        
        address old = feeRecipient;
        feeRecipient = newRecipient;

        emit FeeRecipientUpdated(old, newRecipient);
    }

    /// @notice Update admin address
    /// @dev Only callable by current admin
    /// @param newAdmin New admin address
    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(newAdmin != address(0), "GLUSD: zero admin address");

        address oldAdmin = admin;
        admin = newAdmin;

        emit AdminUpdated(oldAdmin, newAdmin);
    }

    /// @notice Update pauser address
    /// @dev Only callable by admin
    /// @param newPauser New pauser address
    function setPauser(address newPauser) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(newPauser != address(0), "GLUSD: zero pauser address");

        address oldPauser = pauser;
        pauser = newPauser;

        emit PauserUpdated(oldPauser, newPauser);
    }

    /// @notice Emergency token rescue (cannot rescue USDC backing)
    /// @dev Only callable by admin
    /// @param token Token to rescue
    /// @param to Address to send tokens to
    /// @param amount Amount to rescue
    function rescueERC20(IERC20 token, address to, uint256 amount) external {
        require(msg.sender == admin, "GLUSD: only admin");
        require(address(token) != address(USDC), "GLUSD: cannot rescue USDC");
        require(to != address(0), "GLUSD: zero address");

        bool success = token.transfer(to, amount);
        require(success, "GLUSD: rescue transfer failed");
    }
}
