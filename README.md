# GLUSD - Galaksio USD

A yield-bearing stablecoin backed by USDC. Value accrues through exchange rate appreciation as revenue from Galaksio's x402 services is deposited into the vault.

## Deployed Contracts (Avalanche Mainnet)

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| **GLUSD**                   | `0xbE5577295bbfe5261f7FD0E2dc6B29c7F14405f7` |
| **Compute RevenueSplitter** | `0xa989F99a8de7f122b037F1844609305279725737` |
| **Storage RevenueSplitter** | `0xb31E12Ac0c290339eCd793BCdc5B44033D044F1D` |

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

**GLUSD**: Users mint GLUSD by depositing USDC at the current exchange rate. The exchange rate increases when x402 service revenue is deposited, creating yield for all holders.

**RevenueSplitter**: Each x402 service (storage, compute) has its own splitter that distributes revenue to configured recipients, including the GLUSD vault.

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
