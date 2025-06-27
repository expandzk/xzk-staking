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

export class Config {
  private static chainConfigs: { [network: string]: ChainConfig } = {
    'ethereum': {
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
    'sepolia': {
      chainId: 11155111,
      decimals: 18,
      xzkContract: '0x932161e47821c6F5AE69ef329aAC84be1E547e53',
      vXZkContract: '0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587',
      providers: ['https://eth-sepolia.public.blastapi.io', 'https://1rpc.io/sepolia	'],
      sXZK365d: '0x0000000000000000000000000000000000000000',
      sXZK180d: '0x0000000000000000000000000000000000000000',
      sXZK90d: '0x0000000000000000000000000000000000000000',
      sXZKFlex: '0x0000000000000000000000000000000000000000',
      sVXZK365d: '0x0000000000000000000000000000000000000000',
      sVXZK180d: '0x0000000000000000000000000000000000000000',
      sVXZK90d: '0x0000000000000000000000000000000000000000',
      sVXZKFlex: '0x0000000000000000000000000000000000000000',
    },
    'dev': {
      chainId: 11155111,
      decimals: 18,
      xzkContract: '0x932161e47821c6F5AE69ef329aAC84be1E547e53',
      vXZkContract: '0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587',
      providers: ['https://eth-sepolia.public.blastapi.io', 'https://1rpc.io/sepolia	'],
      sXZK365d: '0x9215aa5a101A53fa409ab675a36129732c948564',
      sXZK180d: '0xF2050F78eCcfffcB2E6a6190d6E7c6E488fDF98d',
      sXZK90d: '0x25D950feA1179561d542827cE0EeDEC4ea959F11',
      sXZKFlex: '0x40fe37cCBd2d0c97e0b0360359eD47C412e2e260',
      sVXZK365d: '0xf14e2B92Ab22E5c549a75A568c1D76107bB244Fd',
      sVXZK180d: '0xBd9BB6b7680202b0a48b4C34Bcae5C226975abaB',
      sVXZK90d: '0xcE3347535bc4481D974C582E3f3b6e83bF4fEd45',
      sVXZKFlex: '0x51E157E834575Fff9B145b20F470B1E6555f2D1c',
    },
  };

  private readonly config: ChainConfig;

  public constructor(network: string) {
    const config = Config.chainConfigs[network];
    if (!config) {
      throw new Error(`Unsupported network: ${network}`);
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

  public totalDurationSeconds(): number {
    return 3 * 365 * 24 * 60 * 60;
  }

  public claimDelaySeconds(): number {
    return 24 * 60 * 60;
  }

  public stakingPeriodSeconds(period: StakingPeriod): number {
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
