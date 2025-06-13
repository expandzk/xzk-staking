import '@nomicfoundation/hardhat-ethers';
import '@nomicfoundation/hardhat-chai-matchers';
import * as dotenv from 'dotenv';
import { HardhatUserConfig } from 'hardhat/types';
import 'solidity-coverage';

dotenv.config();

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {},
    localhost: { timeout: 600000 },
  },
  solidity: {
    version: '0.8.26',
    settings: {
      optimizer: {
        enabled: true,
        runs: 800,
        details: {
          yul: true,
        },
      },
    },
  },
  mocha: {
    timeout: 600000,
  },
};

export default config;
