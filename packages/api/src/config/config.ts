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
      sXZK365d: '0x270f7E593fd538b07f0606DF3624C606b55a9043',
      sXZK180d: '0x35Da8E53E7d9c7D5899eE7BE54f2122DaE214BD8',
      sXZK90d: '0xfEE16A342Fbd9119dD80bF9305289A7CBfb01A70',
      sXZKFlex: '0x824B707B48D48C589E6E97D600BE8104158D0a42',
      svXZK365d: '0x7C9e12FFA3084D68975f480b99bBe817E1Dcf994',
      svXZK180d: '0xC11d2d8A667c609E380A3E75cE2D540B529D1e8e',
      svXZK90d: '0x51bbcEBe2FD4C0cFCcAc16dD6bffb91FDb891d0E',
      svXZKFlex: '0x793463a437EA6bc29B748008Ca4483E7A350903a',
      // sXZK365dV1: '0x292Cc9a88FCf0D68Eb561cca105568b317f0e4CE',
      // sXZK180dV1: '0xF2b429c751a09Fe4C5F09d24453175511801270c',
      // sXZK90dV1: '0x39bCCe141B5E1754A3534511b529F3030F7172bA',
      // sXZKFlexV1: '0x43f15F0a9EEf7d2Ea10D6A3A71C38B88B1db0Eb8',
      // svXZK365dV1: '0xF566aceC92AeA720D782727C2fD8aEeC60ea6D9A',
      // svXZK180dV1: '0x663a3f16938Bea331517758e6a126dB04A95c11E',
      // svXZK90dV1: '0x3F477B2468c2C28c21316029A215c66176ce4aaF',
      // svXZKFlexV1: '0x3C00b5960411F842d3B6610d5541f098D2b82e35',
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
      sXZK365d: '0x3bf6290d1E91be18B58985b37C8a390EBabA9Eb8',
      sXZK180d: '0x70D6320e24E2e4A5da123580d430e924ACEfEc3B',
      sXZK90d: '0x7379860dBf7B5063B8657df9b7563089f22CdD5c',
      sXZKFlex: '0x71e1c6861c124b9f9198F6C2E4aBB42843E92565',
      svXZK365d: '0x5fFE828503F9D25d541a0CCc0eD483e2735FB639',
      svXZK180d: '0x71eD904d4a50E11270Dd7d252DcFca98aBB532fF',
      svXZK90d: '0xD7F5f390A6Bf5d2c315Fa13a06eaA670881a74C7',
      svXZKFlex: '0x9fF3C551397d7C8C5251c1FA6faeFd5e90ec04fE',
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
    } else if (this.network === 'sepolia') {
      return Promise.resolve(1754438400);
    }
    return Promise.resolve(1754438400);
  }

  public totalReward(tokenName: TokenName, stakingPeriod: StakingPeriod): Promise<number> {
    if (this.network === 'dev') {
      if ((stakingPeriod as string) === '365d') {
        return Promise.resolve(20000);
      } else if ((stakingPeriod as string) === '180d') {
        return Promise.resolve(15000);
      } else if ((stakingPeriod as string) === '90d') {
        return Promise.resolve(10000);
      } else if ((stakingPeriod as string) === 'Flex') {
        return Promise.resolve(5000);
      }
      return Promise.reject(new Error(`Unsupported staking period for dev network: ${stakingPeriod}`));
    } else {
      if ((tokenName as string) === 'XZK') {
        if ((stakingPeriod as string) === '365d') {
          return Promise.resolve(11000000);
        } else if ((stakingPeriod as string) === '180d') {
          return Promise.resolve(5400000);
        } else if ((stakingPeriod as string) === '90d') {
          return Promise.resolve(2600000);
        } else if ((stakingPeriod as string) === 'Flex') {
          return Promise.resolve(1000000);
        }
        return Promise.reject(new Error(`Unsupported staking period for XZK: ${stakingPeriod}`));
      } else {
        if ((stakingPeriod as string) === '365d') {
          return Promise.resolve(16500000);
        } else if ((stakingPeriod as string) === '180d') {
          return Promise.resolve(8100000);
        } else if ((stakingPeriod as string) === '90d') {
          return Promise.resolve(3900000);
        } else if ((stakingPeriod as string) === 'Flex') {
          return Promise.resolve(1500000);
        }
        return Promise.reject(new Error(`Unsupported staking period for vXZK: ${stakingPeriod}`));
      }
    }
  }
}

export function allTotalReward(network: string, tokenName: TokenName): number {
  if (network === 'dev') {
    return 50000;
  }
  if (tokenName === 'XZK') {
    return 50000000 * 0.4;
  } else {
    return 50000000 * 0.6;
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
