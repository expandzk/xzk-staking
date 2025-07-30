import type { ClientOptions, StakingPeriod, Network, TokenName } from '../api';

export type ChainConfig = {
  chainId: number;
  decimals: number;
  xzkContract: string;
  vXZkContract: string;
  sXZK365d: string;
  sXZK180d: string;
  sXZK90d: string;
  sXZKFlex: string;
  svXZK365d: string;
  svXZK180d: string;
  svXZK90d: string;
  svXZKFlex: string;
  providers: string[];
  etherscanUrl: string;
};

export function clientOptionToKey(options: ClientOptions): string {
  return `s${options.tokenName}${options.stakingPeriod}`;
}

export function round(amount: number): number {
  const precision = 4;
  return Math.round(amount * 10 ** precision) / 10 ** precision;
}

export class Config {
  private static chainConfigs: { [network: string]: ChainConfig } = {
    ethereum: {
      chainId: 1,
      decimals: 18,
      xzkContract: '0xe8fC52b1bb3a40fd8889C0f8f75879676310dDf0',
      vXZkContract: '0x16aFFA80C65Fd7003d40B24eDb96f77b38dDC96A',
      providers: [
        'https://mainnet.gateway.tenderly.co',
        'https://eth-mainnet.public.blastapi.io',
        'https://ethereum.public.blockpi.network/v1/rpc/public',
        'https://eth.api.onfinality.io/public',
        'https://1rpc.io/eth',
        'https://core.gashawk.io/rpc',
        'https://rpc.payload.de',
        'https://eth-pokt.nodies.app',
        'https://eth.drpc.org',
        'https://eth.llamarpc.com',
        'https://ethereum.publicnode.com',
        'https://eth.rpc.blxrbdn.com',
        'https://ethereum-rpc.publicnode.com',
        'https://api.zan.top/eth-mainnet',
        'https://eth.merkle.io',
        'https://ethereum.rpc.subquery.network/public',
        'https://ethereum.therpc.io',
      ],
      etherscanUrl: 'https://etherscan.io',
      sXZK365d: '0x292Cc9a88FCf0D68Eb561cca105568b317f0e4CE',
      sXZK180d: '0xF2b429c751a09Fe4C5F09d24453175511801270c',
      sXZK90d: '0x39bCCe141B5E1754A3534511b529F3030F7172bA',
      sXZKFlex: '0x43f15F0a9EEf7d2Ea10D6A3A71C38B88B1db0Eb8',
      svXZK365d: '0xF566aceC92AeA720D782727C2fD8aEeC60ea6D9A',
      svXZK180d: '0x663a3f16938Bea331517758e6a126dB04A95c11E',
      svXZK90d: '0x3F477B2468c2C28c21316029A215c66176ce4aaF',
      svXZKFlex: '0x3C00b5960411F842d3B6610d5541f098D2b82e35',
    },
    sepolia: {
      chainId: 11155111,
      decimals: 18,
      xzkContract: '0x932161e47821c6F5AE69ef329aAC84be1E547e53',
      vXZkContract: '0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587',
      providers: [
        'https://sepolia.gateway.tenderly.co',
        'https://sepolia.drpc.org',
        'https://1rpc.io/sepolia',
        'https://eth-sepolia.api.onfinality.io/public',
        'https://ethereum-sepolia.rpc.subquery.network/public',
        'https://rpc.sepolia.ethpandaops.io',
        'https://rpc-sepolia.rockx.com',
        'https://eth-sepolia.public.blastapi.io',
        'https://ethereum-sepolia-rpc.publicnode.com',
      ],
      etherscanUrl: 'https://sepolia.etherscan.io',
      sXZK365d: '0x15C591e9b8eBcA87bbc5949485891e1a6080c78F',
      sXZK180d: '0xF1e2a8d8b816E66A6D44ca1e8a46d7D6878b133a',
      sXZK90d: '0x8F786F13d26f57B335124ad847a0761532E8A95E',
      sXZKFlex: '0xD6978Bb5f275bFE911E75F34a892A9070212C25D',
      svXZK365d: '0x806Cf07c06ccA1526040bb045040E3a343C78312',
      svXZK180d: '0x321918A7d1c4b0A3145b2186d2450061144f3D1a',
      svXZK90d: '0x776C1246a5405958C0ACbc5638510c59449F3817',
      svXZKFlex: '0xCA0B5a635fd4A688b10A4626beD9d24c1949Ad17',
    },
    dev: {
      chainId: 11155111,
      decimals: 18,
      xzkContract: '0x932161e47821c6F5AE69ef329aAC84be1E547e53',
      vXZkContract: '0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587',
      providers: [
        'https://sepolia.gateway.tenderly.co',
        'https://sepolia.drpc.org',
        'https://1rpc.io/sepolia',
        'https://eth-sepolia.api.onfinality.io/public',
        'https://ethereum-sepolia.rpc.subquery.network/public',
        'https://rpc.sepolia.ethpandaops.io',
        'https://rpc-sepolia.rockx.com',
        'https://eth-sepolia.public.blastapi.io',
        'https://ethereum-sepolia-rpc.publicnode.com',
      ],
      etherscanUrl: 'https://sepolia.etherscan.io',
      sXZK365d: '0x91763ed454942ba2212Ba96a75AB26c3f4A650F7',
      sXZK180d: '0x5EEB0eCeB07353a4E0B92C4BD7A2846E6D73f416',
      sXZK90d: '0xA0E14203Fb97c3dc31A79cD389DA4910468F4b42',
      sXZKFlex: '0x28f5c6030eC023B593450AC4b942020b7189bFA9',
      svXZK365d: '0x3Fd6A64d7AD73Bd9bcd64116fFe7dC3c7be7aC66',
      svXZK180d: '0xa90CAac345e52Cd53940c54C74714B7B35712071',
      svXZK90d: '0xa524Eb203Da56cE94C094E59b4533282458623f4',
      svXZKFlex: '0xF63F637f9759755d6084862347e29c00cd3AB6b2',
    },
  };

  private readonly network: string;

  private readonly config: ChainConfig;

  public constructor(network: string) {
    const config = Config.chainConfigs[network];
    if (!config) {
      throw new Error(`Unsupported network: ${network}`);
    }
    this.network = network;
    this.config = config;
  }

  public get chainId(): number {
    return this.config.chainId;
  }

  public get etherscanUrl(): string {
    return this.config.etherscanUrl;
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

  public tokenContractAddress(options: ClientOptions): string {
    if (options.tokenName === 'XZK') {
      return this.config.xzkContract;
    }
    return this.config.vXZkContract;
  }

  public stakingContractAddress(options: ClientOptions): string {
    const keyName = clientOptionToKey(options);
    return this.config[keyName as keyof typeof this.config] as string;
  }

  public stakingTokenName(options: ClientOptions): string {
    return 's' + options.tokenName + '-' + options.stakingPeriod;
  }

  public totalDurationSeconds(): number {
    if (this.network === 'dev') {
      return 4 * 60 * 60;
    }
    return 3 * 365 * 24 * 60 * 60;
  }

  public claimDelaySeconds(): number {
    if (this.network === 'dev') {
      return 10 * 60;
    }
    return 24 * 60 * 60;
  }

  public stakingPeriodSeconds(period: StakingPeriod): number {
    if (this.network === 'dev') {
      if (period === '365d') {
        return 60 * 60;
      }
      if (period === '180d') {
        return 30 * 60;
      }
      if (period === '90d') {
        return 10 * 60;
      }
      if (period === 'Flex') {
        return 0;
      }
      throw new Error(`Unsupported staking period: ${period}`);
    }

    if (period === '365d') {
      return 365 * 24 * 60 * 60;
    }
    if (period === '180d') {
      return 180 * 24 * 60 * 60;
    }
    if (period === '90d') {
      return 90 * 24 * 60 * 60;
    }
    if (period === 'Flex') {
      return 0;
    }
    throw new Error(`Unsupported staking period: ${period}`);
  }

  public stakingStartTime(): Promise<number> {
    if (this.network === 'dev') {
      return Promise.resolve(1753848000);
    }
    return Promise.resolve(1754438400);
  }

  public totalReward(tokenName: TokenName, stakingPeriod: StakingPeriod): Promise<number> {
    if (this.network === 'dev') {
      if (stakingPeriod === '365d') {
        return Promise.resolve(20000);
      }
      if (stakingPeriod === '180d') {
        return Promise.resolve(15000);
      }
      if (stakingPeriod === '90d') {
        return Promise.resolve(10000);
      }
      if (stakingPeriod === 'Flex') {
        return Promise.resolve(5000);
      }
    } else {
      if (tokenName === 'XZK') {
        if (stakingPeriod === '365d') {
          return Promise.resolve(11000000);
        }
        if (stakingPeriod === '180d') {
          return Promise.resolve(5400000);
        }
        if (stakingPeriod === '90d') {
          return Promise.resolve(2600000);
        }
        if (stakingPeriod === 'Flex') {
          return Promise.resolve(1000000);
        }
      } else {
        if (stakingPeriod === '365d') {
          return Promise.resolve(16500000);
        }
        if (stakingPeriod === '180d') {
          return Promise.resolve(8100000);
        }
        if (stakingPeriod === '90d') {
          return Promise.resolve(3900000);
        }
        if (stakingPeriod === 'Flex') {
          return Promise.resolve(1500000);
        }
      }
    }
    return Promise.resolve(0);
  }
}

export const GlobalClientOptions: ClientOptions[] = [
  {
    tokenName: 'XZK',
    stakingPeriod: '365d',
  },
  {
    tokenName: 'vXZK',
    stakingPeriod: '365d',
  },
  {
    tokenName: 'XZK',
    stakingPeriod: '180d',
  },
  {
    tokenName: 'vXZK',
    stakingPeriod: '180d',
  },
  {
    tokenName: 'XZK',
    stakingPeriod: '90d',
  },
  {
    tokenName: 'vXZK',
    stakingPeriod: '90d',
  },
  {
    tokenName: 'XZK',
    stakingPeriod: 'Flex',
  },
  {
    tokenName: 'vXZK',
    stakingPeriod: 'Flex',
  },
];
