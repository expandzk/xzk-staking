import type { ClientOptions, StakingPeriod, Network } from '../api';

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
      providers: [
        'https://eth-mainnet.nodereal.io/v1/1659dfb40aa24bbb8153a677b98064d7',
        'https://rpc.flashbots.net',
        'https://mainnet.gateway.tenderly.co',
        'https://core.gashawk.io/rpc',
        'https://rpc.payload.de',
        'https://eth.api.onfinality.io/public',
        'https://eth-pokt.nodies.app',
        'https://eth.drpc.org',
        'https://eth.llamarpc.com',
        'https://1rpc.io/eth',
        'https://ethereum.publicnode.com',
        'https://eth-mainnet.public.blastapi.io',
        'https://eth.rpc.blxrbdn.com',
        'https://ethereum-rpc.publicnode.com',
        'https://ethereum.public.blockpi.network/v1/rpc/public',
        'https://api.zan.top/eth-mainnet',
        'https://eth.merkle.io',
        'https://ethereum.rpc.subquery.network/public',
        'https://ethereum.therpc.io',
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
      sXZK365d: '0x0000000000000000000000000000000000000000',
      sXZK180d: '0x0000000000000000000000000000000000000000',
      sXZK90d: '0x0000000000000000000000000000000000000000',
      sXZKFlex: '0x0000000000000000000000000000000000000000',
      sVXZK365d: '0x0000000000000000000000000000000000000000',
      sVXZK180d: '0x0000000000000000000000000000000000000000',
      sVXZK90d: '0x0000000000000000000000000000000000000000',
      sVXZKFlex: '0x0000000000000000000000000000000000000000',
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
      sXZK365d: '0xd55e9cDF6D4340492b071805F64EBC65473ABEfd',
      sXZK180d: '0x74B77D7f9A0601118582E7004C350496C5064AFD',
      sXZK90d: '0xBa2c8bFBB7b650344C07245975cCD9763c077439',
      sXZKFlex: '0x583e7927728A857630c7AE87B7C7b6a1BfEb15b6',
      sVXZK365d: '0x99dD86F0cDe9CBEfe93920ee455f10E52Fb61912',
      sVXZK180d: '0xa4fC81A6f0Be4A45a7880E87296c0178726FA847',
      sVXZK90d: '0x1C7488724c00c5aD7f3b67203c835130e08B8e7b',
      sVXZKFlex: '0x7e09b266571A4e194C74f5DE4CDB50a469EfB152',
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
      return 14 * 24 * 60 * 60;
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
        return 3 * 24 * 60 * 60;
      }
      if (period === '180d') {
        return 2 * 24 * 60 * 60;
      }
      if (period === '90d') {
        return 1 * 24 * 60 * 60;
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
}

export const GlobalClientOptions: ClientOptions[] = [
  {
    tokenName: 'XZK',
    stakingPeriod: '365d',
  },
  {
    tokenName: 'VXZK',
    stakingPeriod: '365d',
  },
  {
    tokenName: 'XZK',
    stakingPeriod: '180d',
  },
  {
    tokenName: 'VXZK',
    stakingPeriod: '180d',
  },
  {
    tokenName: 'XZK',
    stakingPeriod: '90d',
  },
  {
    tokenName: 'VXZK',
    stakingPeriod: '90d',
  },
  {
    tokenName: 'XZK',
    stakingPeriod: 'Flex',
  },
  {
    tokenName: 'VXZK',
    stakingPeriod: 'Flex',
  },
];
