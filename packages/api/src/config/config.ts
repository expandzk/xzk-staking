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
      sXZK365d: '0x0297b171bE11B700Ec003AeBC83B88c0668229F9',
      sXZK180d: '0xC8324e675b73eed0fAFE80593744C477e18899C6',
      sXZK90d: '0x611dcB377652E9799152DB639fc4C9e3DE5Db245',
      sXZKFlex: '0x4AE71CEfa8141e785bef19532D3d5791922c9753',
      sVXZK365d: '0x4C816e411c244E864710F4faddBb7F8FbAe774d5',
      sVXZK180d: '0xCe27738836A51dA2bbA95Fef0C8CDBB99604CEa8',
      sVXZK90d: '0x5B8E4AcA084Cd844adFc20Fadb31dF8666588834',
      sVXZKFlex: '0x30778e6d3AF77dcd36930a840445F84d4B50f913',
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
