import {
  MystikoStakingContractFactory,
  ERC20ContractFactory,
  MystikoStaking,
  ERC20,
} from '@expandzk/xzk-staking-abi';
import { providers } from 'ethers';
import type { StakingContractName } from '../index';

export type ChainConfig = {
  chainId: number;
  decimals: number;
  xzkContract: string;
  vXZkContract: string;
  sXZK365d: string;
  sXZK180d: string;
  sXZK90d: string;
  sXZKFlex: string;
  sVXZK365d: string;
  sVXZK180d: string;
  sVXZK90d: string;
  sVXZKFlex: string;
  providers: string[];
};

export class Config {
  private static chainConfigs: { [chainId: number]: ChainConfig } = {
    1: {
      chainId: 1,
      decimals: 18,
      providers: [
        'https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
        'https://eth-mainnet.public.blastapi.io',
        'https://ethereum-rpc.publicnode.com',
        'https://eth.drpc.org',
        'https://rpc.ankr.com/eth',
        'https://rpc.flashbots.net',
      ],
      xzkContract: '0xe8fC52b1bb3a40fd8889C0f8f75879676310dDf0',
      vXZkContract: '0x16aFFA80C65Fd7003d40B24eDb96f77b38dDC96A',
      sXZK365d: '0x0000000000000000000000000000000000000000',
      sXZK180d: '0x0000000000000000000000000000000000000000',
      sXZK90d: '0x0000000000000000000000000000000000000000',
      sXZKFlex: '0x0000000000000000000000000000000000000000',
      sVXZK365d: '0x0000000000000000000000000000000000000000',
      sVXZK180d: '0x0000000000000000000000000000000000000000',
      sVXZK90d: '0x0000000000000000000000000000000000000000',
      sVXZKFlex: '0x0000000000000000000000000000000000000000',
    },
    11155111: {
      chainId: 11155111,
      decimals: 18,
      xzkContract: '0x932161e47821c6F5AE69ef329aAC84be1E547e53',
      vXZkContract: '0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587',
      providers: ['https://eth-sepolia.public.blastapi.io', 'https://1rpc.io/sepolia	'],
      sXZK365d: '0x9cC6b3fE97c1F03eF74f369e61A2e87DD83B2EDF',
      sXZK180d: '0xe4D932b62783953FE693069a09308f27DA8140c9',
      sXZK90d: '0x1C91E9b6A81F92FEab337e206Bf218a30Bf581E2',
      sXZKFlex: '0x59bAe9b5c007Cb0e06bad64E4DD69788A51321BA',
      sVXZK365d: '0xb5971b52775735CcfD361251FF3982b0a71CD971',
      sVXZK180d: '0x97DFa99097C5b8A359B947c63b131022ac33606d',
      sVXZK90d: '0xd72627C7168434DC4a8f9Fa9e3E09951814bDeaE',
      sVXZKFlex: '0x5958D56dB3ED16471989359005beB9bE5d430AAd',
    },
  };

  private readonly config: ChainConfig;

  public constructor(chainId: number) {
    const config = Config.chainConfigs[chainId];
    if (!config) {
      throw new Error(`Unsupported chain ID: ${chainId}`);
    }
    this.config = config;
  }

  public get chainId(): number {
    return this.config.chainId;
  }

  public get decimals(): number {
    return this.config.decimals;
  }

  public get xzkContract(): string {
    return this.config.xzkContract;
  }

  public get vXZkContract(): string {
    return this.config.vXZkContract;
  }

  public get providers(): string[] {
    return this.config.providers;
  }

  public tokenContractAddress(name: StakingContractName): string {
    if (name === 'sXZK365d' || name === 'sXZK180d' || name === 'sXZK90d' || name === 'sXZKFlex') {
      return this.config.xzkContract;
    }
    return this.config.vXZkContract;
  }

  public stakingContractAddress(name: StakingContractName): string {
    return this.config[name as keyof typeof this.config] as string;
  }

  public tokenContractInstance(provider: providers.Provider, name: StakingContractName): ERC20 {
    if (name === 'sXZK365d' || name === 'sXZK180d' || name === 'sXZK90d' || name === 'sXZKFlex') {
      return ERC20ContractFactory.connect('ERC20', this.config.xzkContract, provider);
    }
    if (name === 'sVXZK365d' || name === 'sVXZK180d' || name === 'sVXZK90d' || name === 'sVXZKFlex') {
      return ERC20ContractFactory.connect('ERC20', this.config.vXZkContract, provider);
    }
    throw new Error(`Unsupported staking contract name: ${name}`);
  }

  public stakingContractInstance(provider: providers.Provider, name: StakingContractName): MystikoStaking {
    const contractAddress = this.config[name as keyof typeof this.config] as string;
    return MystikoStakingContractFactory.connect<MystikoStaking>('MystikoStaking', contractAddress, provider);
  }

  public totalDurationSeconds(): number {
    return 3 * 365 * 24 * 60 * 60;
  }

  public claimDelaySeconds(): number {
    return 24 * 60 * 60;
  }

  public stakingPeriodSeconds(name: StakingContractName): number {
    if (name === 'sXZK365d' || name === 'sVXZK365d') {
      return 365 * 24 * 60 * 60;
    }
    if (name === 'sXZK180d' || name === 'sVXZK180d') {
      return 180 * 24 * 60 * 60;
    }
    if (name === 'sXZK90d' || name === 'sVXZK90d') {
      return 90 * 24 * 60 * 60;
    }
    if (name === 'sXZKFlex' || name === 'sVXZKFlex') {
      return 0;
    }
    throw new Error(`Unsupported staking contract name: ${name}`);
  }
}
