# GLUSD - Galaksio USD

A yield-bearing stablecoin backed by USDC. Value accrues through exchange rate appreciation as revenue from Galaksio's x402 services is deposited into the vault.

## Deployed Contracts (Avalanche Mainnet)

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| **GLUSD**                   | `0xD0105DB38fe58196bb138965489Bf7c982010422` |
| **Compute RevenueSplitter** | `0xf18f7029dCC14Fb93d0b1B78027F15a9c943E359` |
| **Storage RevenueSplitter** | `0x864B43e3e76aEBFFA6f254000b70ff8FC5FCD624` |

**Network**: Avalanche C-Chain (43114)
**USDC**: `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E`

## Repository Structure

```
.
├── contracts/          # Foundry project
│   ├── src/           # Smart contracts
│   │   ├── GLUSD.sol              # Main yield-bearing stablecoin vault
│   │   └── RevenueSplitter.sol    # Revenue distribution for x402 services
│   ├── script/        # Deployment scripts
│   ├── test/          # Contract tests
│   ├── deployments/   # Deployment addresses and transaction hashes
│   └── lib/           # Dependencies (OpenZeppelin, Forge-std)
│
└── scripts/           # Python scripts for deployment and management
```

## How It Works

### GLUSD Token

GLUSD is a non-rebasing yield-bearing stablecoin where value accrues through exchange rate appreciation rather than balance increases.

**Exchange Rate**: The rate of USDC per GLUSD, calculated as:

```
exchangeRate = (total USDC in vault * 1e6) / total GLUSD supply
```

Initially starts at 1:1 and increases as revenue is deposited into the vault.

#### Minting GLUSD

Users deposit USDC to receive GLUSD at the current exchange rate:

1. User approves USDC and calls `mint(usdcAmount)`
2. A **0.5% fee** is deducted and sent to the `feeRecipient`
3. Remaining USDC (99.5%) is deposited into the vault
4. GLUSD is minted based on: `glusdMinted = (amountAfterFee * 1e6) / exchangeRate`

**Example**: If you deposit 1000 USDC at 1.05 exchange rate:

- Fee: 5 USDC (0.5%) → sent to feeRecipient
- Deposited: 995 USDC → added to vault
- Minted: 947.62 GLUSD = (995 \* 1e6) / 1.05e6

#### Redeeming GLUSD

Users burn GLUSD to receive USDC at the current exchange rate:

1. User calls `redeem(glusdAmount)`
2. GLUSD is burned
3. USDC value calculated: `usdcGross = (glusdAmount * exchangeRate) / 1e6`
4. A **0.5% fee** is deducted from the USDC and sent to the `feeRecipient`
5. Remaining USDC (99.5%) is transferred to the user

**Example**: If you redeem 100 GLUSD at 1.05 exchange rate:

- Gross USDC: 105 USDC = (100 \* 1.05e6) / 1e6
- Fee: 0.525 USDC (0.5%) → sent to feeRecipient
- Received: 104.475 USDC → transferred to user

#### APR/APY Calculations

GLUSD tracks exchange rate over time using a circular buffer of snapshots:

- **Snapshot buffer**: 2160 snapshots (up to 90 days at ~1 snapshot/hour)
- **Snapshot interval**: Minimum 30 seconds between snapshots
- Snapshots are taken automatically when fees are deposited or manually via `takeSnapshot()`

**APR (Annual Percentage Rate)**: Simple interest annualized

```
APR = (rateIncrease / oldRate) * (SECONDS_PER_YEAR / timeElapsed) * 100
```

**APY (Annual Percentage Yield)**: Compound interest annualized

```
APY ≈ (currentRate/oldRate - 1) * (SECONDS_PER_YEAR / timeElapsed) * 100
```

Available functions:

- `calculateAPR(daysAgo)` - APR for any period (max 90 days)
- `calculateAPY(daysAgo)` - APY for any period (max 90 days)
- `getCurrentAPRs()` - Returns both 7-day and 30-day APR

#### Fee Recipient

The `feeRecipient` address receives all mint/redeem fees (0.5% each):

- Configurable by admin via `setFeeRecipient()`
- Separate from the vault's USDC backing
- Used to cover operational costs or protocol revenue

#### Key GLUSD Functions

**User Functions**:

- `mint(usdcAmount)` - Deposit USDC to mint GLUSD
- `redeem(glusdAmount)` - Burn GLUSD to withdraw USDC
- `exchangeRate()` - Get current USDC per GLUSD rate
- `vaultStatus()` - View total USDC and GLUSD supply
- `calculateAPR(daysAgo)` - Calculate APR for a time period
- `calculateAPY(daysAgo)` - Calculate APY for a time period
- `getCurrentAPRs()` - Get 7-day and 30-day APR

**Treasury Functions**:

- `depositFees(amount)` - Deposit revenue to increase exchange rate (treasury only)

**Admin Functions**:

- `addTreasury(address)` / `removeTreasury(address)` - Manage treasury addresses
- `setFeeRecipient(address)` - Update fee recipient
- `pause()` / `unpause()` - Emergency controls
- `setAdmin(address)` / `setPauser(address)` - Role management

### RevenueSplitter Contracts

**RevenueSplitter** contracts receive USDC revenue from x402 services and automatically distribute it to configured recipients based on basis points (bps).

#### How RevenueSplitters Work

1. **Revenue Collection**: x402 services send USDC payments to the RevenueSplitter contract
2. **Distribution**: Anyone can call `distribute()` to split accumulated USDC among recipients
3. **Basis Points**: Each recipient gets a share based on their bps (1 bp = 0.01%, 10000 bps = 100%)
4. **Automation**: Chainlink Automation can trigger distributions based on time interval and minimum balance

**Current Configuration**:
75% of x402 revenues go towards Galaksio operating costs
25% of revenues go to the GLUSD vault

#### GLUSD Integration

When the GLUSD vault is configured as a recipient:

1. RevenueSplitter calculates the vault's share based on bps
2. Approves GLUSD contract to pull the USDC
3. Calls `GLUSD.depositFees(share)` which deposits USDC into the vault
4. This increases the exchange rate, creating yield for all GLUSD holders

#### Active RevenueSplitters

Currently deployed for x402 services (**Broker RevenueSplitter is NOT in use**):

- **Compute RevenueSplitter** (`0xa989F99a8de7f122b037F1844609305279725737`) - Distributes compute service revenue
- **Storage RevenueSplitter** (`0xb31E12Ac0c290339eCd793BCdc5B44033D044F1D`) - Distributes storage service revenue

Each RevenueSplitter independently manages its recipients and distribution schedule.

## Development

```bash
# Build
cd contracts && forge build

# Test
forge test

# Deploy
forge script script/Deploy.s.sol --rpc-url avalanche --broadcast
```

## License

TBA
