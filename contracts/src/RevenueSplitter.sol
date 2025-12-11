// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title RevenueSplitter (x402-compatible)
 * @notice Pull-based revenue splitter for USDC where x402 facilitators send USDC transfers
 *         to this contract, and anyone (or Chainlink Automation) can call `distribute()`
 *         to forward shares to configured recipients. Supports calling GLUSD.depositFees
 *         for recipients that are the GLUSD vault contract.
 *
 * Features:
 *  - recipients[] with per-recipient bps (basis points) controlled by admin
 *  - sum(bps) must equal BP_SCALE (10000) to avoid leftover funds ambiguity
 *  - Chainlink Automation-compatible (checkUpkeep/performUpkeep) to auto-call distribute()
 *  - AccessControl for admin & pauser roles
 *  - SafeERC20, ReentrancyGuard, Pausable
 *
 * NOTE: GLUSD.depositFees expects GLUSD to call USDC.transferFrom(msg.sender, address(this), amount)
 *       so this contract must approve GLUSD to pull the GLUSD share before calling depositFees.
 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface IGLUSD {
    function depositFees(uint256 amount) external returns (bool);
}

interface IAutomationCompatible {
    // Minimal interface for Chainlink Automation (Keepers)
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract RevenueSplitter is ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    address public admin;
    address public pauser;

    // BP scale (100.00% == 10000 bps)
    uint256 public constant BP_SCALE = 10000;

    IERC20 public immutable USDC;
    IGLUSD public immutable GLUSD; // optional - may be address(0) if not used in this instance

    // recipients and their bps share. sum(bps) must == BP_SCALE
    address[] public recipients;
    mapping(address => uint256) public bps; // basis points per recipient

    // Chainlink automation params
    uint256 public distributeInterval; // seconds
    uint256 public lastDistributeTimestamp;
    uint256 public minBalanceToDistribute; // min USDC balance to trigger distribution

    event RecipientsUpdated(address[] recipients, uint256[] bps);
    event RecipientAdded(address recipient, uint256 bp);
    event RecipientRemoved(address recipient);
    event Distributed(uint256 totalAmount, uint256 timestamp);
    event DistributedToRecipient(address recipient, uint256 amount, uint256 bp);
    event SetInterval(uint256 interval);
    event SetMinBalance(uint256 minBalance);
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event PauserUpdated(address indexed oldPauser, address indexed newPauser);

    /**
     * @param _usdc USDC token address (6 decimals)
     * @param _glusd GLUSD vault contract address (if you want GLUSD deposit support) - can be zero if not used
     * @param _admin admin address
     * @param _distributeInterval default chainlink interval (seconds)
     * @param _minBalanceToDistribute default minimum USDC balance to trigger distribution
     */
    constructor(
        IERC20 _usdc,
        IGLUSD _glusd,
        address _admin,
        uint256 _distributeInterval,
        uint256 _minBalanceToDistribute
    ) {
        require(address(_usdc) != address(0), "USDC zero");
        require(_admin != address(0), "admin zero");

        USDC = _usdc;
        GLUSD = _glusd;

        admin = _admin;
        pauser = _admin;

        distributeInterval = _distributeInterval;
        minBalanceToDistribute = _minBalanceToDistribute;
        lastDistributeTimestamp = block.timestamp;
    }

    // -------------------------
    // Admin functions
    // -------------------------

    /**
     * @notice Set recipients and their bps atomically. Only admin.
     * @dev `recipients` and `bpsArr` must be same length and sum(bpsArr) must == BP_SCALE.
     */
    function setRecipients(address[] calldata recipients_, uint256[] calldata bpsArr) external whenNotPaused {
        require(msg.sender == admin, "only admin");
        require(recipients_.length == bpsArr.length, "length mismatch");
        require(recipients_.length > 0, "no recipients");

        uint256 totalBp = 0;
        for (uint256 i = 0; i < recipients_.length; i++) {
            address r = recipients_[i];
            uint256 bp = bpsArr[i];
            require(r != address(0), "zero recipient");
            require(bp > 0, "zero bp");

            totalBp += bp;
        }
        require(totalBp == BP_SCALE, "bps must sum to BP_SCALE");

        // clear old mapping
        for (uint256 i = 0; i < recipients.length; i++) {
            delete bps[recipients[i]];
        }

        // set new list & mapping
        for (uint256 i = 0; i < recipients_.length; i++) {
            recipients.push(recipients_[i]);
            bps[recipients_[i]] = bpsArr[i];
        }

        emit RecipientsUpdated(recipients_, bpsArr);
    }

    /**
     * @notice Clear recipients (admin-only). Use with caution.
     */
    function clearRecipients() external {
        require(msg.sender == admin, "only admin");
        for (uint256 i = 0; i < recipients.length; i++) {
            delete bps[recipients[i]];
        }
        delete recipients;
        emit RecipientsUpdated(new address[](0), new uint256[](0));
    } 

    /**
     * @notice Update distribute interval for Chainlink automation
     */
    function setDistributeInterval(uint256 interval) external {
        require(msg.sender == admin, "only admin");
        distributeInterval = interval;
        emit SetInterval(interval);
    }

    /**
     * @notice Update min balance required to trigger distribute
     */
    function setMinBalanceToDistribute(uint256 minBalance) external {
        require(msg.sender == admin, "only admin");
        minBalanceToDistribute = minBalance;
        emit SetMinBalance(minBalance);
    }

    function pause() external {
        require(msg.sender == pauser, "only pauser");
        _pause();
    }

    function unpause() external {
        require(msg.sender == pauser, "only pauser");
        _unpause();
    }

    /**
     * @notice Update admin address
     * @dev Only callable by current admin
     * @param newAdmin New admin address
     */
    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "only admin");
        require(newAdmin != address(0), "zero admin address");

        address oldAdmin = admin;
        admin = newAdmin;

        emit AdminUpdated(oldAdmin, newAdmin);
    }

    /**
     * @notice Update pauser address
     * @dev Only callable by admin
     * @param newPauser New pauser address
     */
    function setPauser(address newPauser) external {
        require(msg.sender == admin, "only admin");
        require(newPauser != address(0), "zero pauser address");

        address oldPauser = pauser;
        pauser = newPauser;

        emit PauserUpdated(oldPauser, newPauser);
    }

    // -------------------------
    // View helpers
    // -------------------------

    function getRecipients() external view returns (address[] memory) {
        return recipients;
    }

    function getBpsForRecipient(address recipient) external view returns (uint256) {
        return bps[recipient];
    }

    // -------------------------
    // Distribution logic
    // -------------------------

    /**
     * @notice Distribute current USDC balance according to configured bps.
     * @dev Approves GLUSD for its share then calls GLUSD.depositFees(share) for GLUSD recipient if present.
     *      For other recipients uses safeTransfer.
     *
     *      This function is x402-compatible: it assumes USDC balance was transferred INTO this contract
     *      by x402 facilitator (or any sender). Anyone can call distribute() (subject to pause).
     */
    function distribute() public nonReentrant whenNotPaused {
        uint256 balance = USDC.balanceOf(address(this));
        require(balance > 0, "no USDC to distribute");
        require(recipients.length > 0, "no recipients configured");

        uint256 totalDistributed = 0;

        // iterate recipients and send their share
        for (uint256 i = 0; i < recipients.length; i++) {
            address r = recipients[i];
            uint256 recipientBp = bps[r];
            // defensive check
            if (recipientBp == 0) continue;

            uint256 share = (balance * recipientBp) / BP_SCALE;
            if (share == 0) continue;

            // If recipient is GLUSD contract address, call depositFees flow:
            if (address(GLUSD) != address(0) && r == address(GLUSD)) {
                // Approve GLUSD to pull funds using forceApprove which handles allowance management
                USDC.forceApprove(address(GLUSD), share);
                require(GLUSD.depositFees(share), "GLUSD deposit failed");
            } else {
                // Normal recipient transfer
                USDC.safeTransfer(r, share);
            }

            emit DistributedToRecipient(r, share, recipientBp);
            totalDistributed += share;
        }

        // If rounding left some dust due to integer division, keep it in contract (or let admin handle)
        // Emit event with totalDistributed
        lastDistributeTimestamp = block.timestamp;
        emit Distributed(totalDistributed, block.timestamp);
    }

    // -------------------------
    // Chainlink Automation compatible hooks
    // -------------------------
    // Minimal implementation suitable for Chainlink automation registration.
    // checkUpkeep should be called by Chainlink nodes and return true if distribute() should be executed.

    /**
     * @notice Chainlink Automation checkUpkeep (compatibility)
     * @dev `checkData` unused here but passed through for future extensibility
     */
    function checkUpkeep(bytes calldata /* checkData */) external view returns (bool upkeepNeeded, bytes memory /* performData */) {
        // Enough time must have passed AND balance must exceed configured min
        if (block.timestamp >= lastDistributeTimestamp + distributeInterval) {
            uint256 balance = USDC.balanceOf(address(this));
            if (balance >= minBalanceToDistribute && recipients.length > 0) {
                upkeepNeeded = true;
            } else {
                upkeepNeeded = false;
            }
        } else {
            upkeepNeeded = false;
        }
        return (upkeepNeeded, bytes(""));
    }

    /**
     * @notice Chainlink Automation performUpkeep (compatibility)
     */
    function performUpkeep(bytes calldata /* performData */) external whenNotPaused {
        // Note: Anyone (including Chainlink) can call this; it will call distribute() which is nonReentrant
        // Re-check conditions for safety
        require(block.timestamp >= lastDistributeTimestamp + distributeInterval, "interval not elapsed");
        uint256 balance = USDC.balanceOf(address(this));
        require(balance >= minBalanceToDistribute, "balance too low");
        distribute();
    }

    // -------------------------
    // Emergency rescue (admin only)
    // -------------------------
    /**
     * @notice Rescue non-USDC ERC20 mistakenly sent to this contract
     * @dev Admin only. Cannot rescue USDC.
     */
    function rescueERC20(IERC20 token, address to, uint256 amount) external {
        require(msg.sender == admin, "only admin");
        require(address(token) != address(USDC), "cannot rescue USDC");
        require(to != address(0), "zero address");
        token.safeTransfer(to, amount);
    }
}
