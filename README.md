# Expand Staking Rewards

A comprehensive staking rewards system for the Expand Network, providing secure and efficient token staking with exponential decay reward mechanisms.

## Overview

This project implements a complete staking rewards ecosystem with smart contracts, TypeScript APIs, and comprehensive tooling. The system supports multiple staking periods (Flex, 90 days, 180 days, 365 days) and provides both XZK and vXZK token staking capabilities.

## Project Structure

This is a monorepo containing three main packages:

```
staking-rewards-dev/
├── packages/
│   ├── contracts/     # Smart contracts and deployment
│   ├── abi/          # Generated ABIs and TypeScript types
│   └── api/          # TypeScript API client
├── package.json      # Root workspace configuration
└── README.md         # This file
```

## Packages

### 📦 @expandzk/xzk-staking-contracts

**Smart Contracts Package**

The core smart contracts implementing the staking rewards system.

#### Key Features:
- **XzkStaking.sol**: Main staking contract with reward distribution
- **XzkStakingRecord.sol**: Record management for staking/unstaking operations
- **XzkStakingToken.sol**: Non-transferable staking token implementation
- **Reward.sol**: Exponential decay reward calculation library
- **Constants.sol**: System constants and configuration

#### Core Functionality:
- **Staking**: Users can stake XZK/vXZK tokens to receive staking tokens
- **Unstaking**: Users can unstake after the staking period ends
- **Claiming**: Users can claim underlying tokens after a 1-day delay
- **Reward Distribution**: Exponential decay mechanism over 3 years
- **Access Control**: DAO-based governance and pause functionality

#### Staking Periods:
- **Flex**: Immediate unstaking capability
- **90 days**: 90-day lock period
- **180 days**: 180-day lock period  
- **365 days**: 365-day lock period

#### Security Features:
- ReentrancyGuard protection
- SafeERC20 for secure token transfers
- Access control for administrative functions
- Pause functionality for emergency situations

#### Development Commands:
```bash
# Build contracts
yarn build:contract

# Run tests
yarn test:forge
yarn test:hardhat

# Generate coverage
yarn coverage

# Format code
yarn format
```

### 📦 @expandzk/xzk-staking-abi

**ABI and TypeScript Types Package**

Automatically generated ABIs and TypeScript type definitions from the smart contracts.

#### Features:
- **TypeScript Types**: Full type safety for contract interactions
- **Ethers.js Integration**: Compatible with ethers.js v5
- **Auto-generation**: Automatically generated from contract artifacts
- **Dual Build**: CommonJS and ES modules support

#### Generated Artifacts:
- Contract ABIs
- TypeScript interfaces
- Factory classes for contract deployment
- Event types and filters

#### Development Commands:
```bash
# Generate ABIs from contracts
yarn generate

# Build package
yarn build

# Format code
yarn format
```

### 📦 @expandzk/xzk-staking-api

**TypeScript API Client Package**

High-level TypeScript API for interacting with the staking contracts.

#### Key Features:
- **Client Interface**: Unified API for all staking operations
- **Multi-Network Support**: Ethereum, Sepolia, and dev networks
- **Type Safety**: Full TypeScript support with generated types
- **Error Handling**: Comprehensive error codes and messages
- **Gas Optimization**: Built-in gas limit checks and optimizations

#### Core API Methods:

##### Pool Information
- `stakingPoolSummary()` - Get pool statistics and reward rates
- `estimatedApr()` - Calculate estimated annual percentage rate
- `stakerApr()` - Get current staker APR
- `totalRewardAt()` - Get total rewards at specific timestamp

##### User Operations
- `stakingSummary()` - Get user's staking information
- `unstakingSummary()` - Get user's unstaking information
- `claimSummary()` - Get user's claim information
- `tokenBalance()` - Get user's token balance
- `stakingBalance()` - Get user's staking token balance

##### Transaction Building
- `stake()` - Build stake transaction
- `unstake()` - Build unstake transaction
- `claim()` - Build claim transaction
- `tokenApprove()` - Build token approval transaction

#### Network Support:
- **Ethereum Mainnet**: Production deployment
- **Sepolia Testnet**: Testing and staging
- **Dev Network**: Development and local testing

#### Development Commands:
```bash
# Build package
yarn build

# Run tests
yarn test
yarn test:integration

# Format code
yarn format
```

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/expandzk/xzk-staking.git
cd mystiko-staking-rewards

# Install dependencies
yarn install

# Build all packages
yarn build
```

### Basic Usage

```typescript
import { stakingApiClient } from '@expandzk/xzk-staking-api';

// Initialize the client
stakingApiClient.initialize({
  network: 'ethereum', // or 'sepolia', 'dev'
});

// Get staking pool information
const poolSummary = await stakingApiClient.stakingPoolSummary({
  tokenName: 'XZK',
  stakingPeriod: '365d'
});

// Get user's staking summary
const userSummary = await stakingApiClient.stakingSummary({
  tokenName: 'XZK',
  stakingPeriod: '365d'
}, '0x...');

// Build a stake transaction
const stakeTx = await stakingApiClient.stake({
  tokenName: 'XZK',
  stakingPeriod: '365d'
}, '0x...', false, 1000);
```

## Architecture

### Smart Contract Architecture

```
XzkStaking (Main Contract)
├── XzkStakingRecord (Record Management)
├── XzkStakingToken (Staking Token)
├── MystikoDAOAccessControl (Governance)
└── ReentrancyGuard (Security)
```

### API Architecture

```
StakingApiClient
├── ContractClient (Low-level contract interaction)
├── Config (Network and contract configuration)
└── Error Handling (Comprehensive error management)
```

## Reward Mechanism

The system uses an exponential decay reward mechanism:

- **Total Reward**: 50 million tokens distributed over 3 years
- **Decay Function**: Exponential decay with lambda parameter
- **Distribution**: Based on staking share ratio
- **Calculation**: Real-time reward calculation using Taylor series approximation

### Reward Formula

```
Reward(t) = TOTAL_REWARD * (1 - e^(-λt))
```

Where:
- `t` = time elapsed since start
- `λ` = decay constant (20e9)
- `TOTAL_REWARD` = 50 million tokens

## Security Features

### Smart Contract Security
- **Reentrancy Protection**: Prevents reentrancy attacks
- **Safe Token Transfers**: Uses OpenZeppelin's SafeERC20
- **Access Control**: Role-based permissions
- **Pause Functionality**: Emergency pause capability
- **Input Validation**: Comprehensive parameter validation

### API Security
- **Type Safety**: Full TypeScript type checking
- **Error Handling**: Comprehensive error codes
- **Gas Optimization**: Built-in gas limit checks
- **Network Validation**: Multi-network support with validation

## Development

### Prerequisites
- Node.js 16+
- Yarn package manager
- Foundry (for contract development)
- Hardhat (for contract compilation)

### Development Workflow

1. **Contract Development**:
   ```bash
   cd packages/contracts
   yarn test:forge
   yarn build:contract
   ```

2. **ABI Generation**:
   ```bash
   cd packages/abi
   yarn generate
   yarn build
   ```

3. **API Development**:
   ```bash
   cd packages/api
   yarn test
   yarn build
   ```

### Testing

```bash
# Run all tests
yarn test

# Run contract tests
cd packages/contracts && yarn test:forge

# Run API tests
cd packages/api && yarn test

# Generate coverage
yarn coverage
```

### Code Quality

```bash
# Format code
yarn format

# Lint code
yarn lint

# Type checking
yarn build
```

## Deployment

### Contract Deployment

Contracts are deployed using Foundry scripts:

```bash
cd packages/contracts
forge script scripts/deploy/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
```

### Configuration

Network configurations are managed in `packages/api/src/config/config.ts`:

- Contract addresses
- Network parameters
- Reward configurations
- Time parameters

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions and support:
- GitHub Issues: [Create an issue](https://github.com/expandzk/xzk-staking/issues)
- Documentation: See individual package READMEs
- Community: Join our Discord/Telegram channels

## Version History

- **v0.1.29**: Current stable release
- Multi-network support (Ethereum, Sepolia, Dev)
- Complete staking lifecycle implementation
- Comprehensive API client
- Full test coverage