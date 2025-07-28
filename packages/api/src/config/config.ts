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
      sXZK365d: '0x286d2DdCf7b6F4bE4B7f73ccaAbd94B83eC41eeb',
      sXZK180d: '0x45FD0dcD6b77AEA7c3B1F1Df75714A3aa367C7c6',
      sXZK90d: '0x3df15066e9e099087f2253df0126687da2Ddc76A',
      sXZKFlex: '0x2AfB0BEA29F47bEA70a5E43Ef09882a8E7923A63',
      sVXZK365d: '0xa69dDc7dDb6acF641bb3a2E68C4be58D9a109462',
      sVXZK180d: '0x798e104e80Defb818DD5aeC8eD1C1C462F8C8d34',
      sVXZK90d: '0xA4dB20804A0242e5eeb1912Ff1ABeF4faB26Cf2D',
      sVXZKFlex: '0x040F9A586895cCc26cEd1cc6df2e2f7e91c1B1f6',
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
