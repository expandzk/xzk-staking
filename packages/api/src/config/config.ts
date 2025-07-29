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
      etherscanUrl: 'https://etherscan.io',
      xzkContract: '0xe8fC52b1bb3a40fd8889C0f8f75879676310dDf0',
      vXZkContract: '0x16aFFA80C65Fd7003d40B24eDb96f77b38dDC96A',
      sXZK365d: '0x83855A5ccc889b0Eb27F1BCb5a61313c1B3D1dA3',
      sXZK180d: '0x01239eB9df6e58fF5d699c37088b68c0391B4bd8',
      sXZK90d: '0x5148D13c3481261631010E9210Db232D046Aef46',
      sXZKFlex: '0x7c899fFa3Ea38d88972ac928b582747d1c8eeC43',
      svXZK365d: '0x97a89784A1Ef6695F4aac037F150674407D496DE',
      svXZK180d: '0xFB76C801771d8E882ccC3f96cb67B13CfEFFd67e',
      svXZK90d: '0x5cf067d59678DC9755Cf069d6Ffb9eDE963e597f',
      svXZKFlex: '0x8FD69c658A24968AbD3286fa7746d7DA590DCE12',
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
      sXZK365d: '0x8353F765B47CC87dcc5F295864a898C0c5651Cf4',
      sXZK180d: '0xC4F93a71017E49278B8594E297c3A8144cF47E84',
      sXZK90d: '0xb29021e44dBa5a1F0C35191FD6D1a4BDa8E72ded',
      sXZKFlex: '0x378803eff090F670EE5b80C0c2e97b42C1eccA2F',
      svXZK365d: '0xbfC46221F86c7f9451e2831B39a9C70fA0820C2D',
      svXZK180d: '0x9fbC51F5dC006E6B2A6717B9F08Fb8EAeb3066a2',
      svXZK90d: '0x3b41F3D8f727F7d78Cb2dE10d90A6EAab4647b81',
      svXZKFlex: '0x1D042C3b0BBcb010D78b25C5D52bc831555edf07',
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
      sXZK365d: '0x7Fdc7984F3527DAaa6D854B0b0f6aF086816F587',
      sXZK180d: '0x41ea9C6Bd5185eb0f044054148Bd2637FF90369E',
      sXZK90d: '0x8b1F1C4FF7eD18e3D031Fc8232C9ec39D02efC51',
      sXZKFlex: '0xF4037D66661C5678FE73A124c579fbFDF720679e',
      svXZK365d: '0x8fa9b7c598C24D781cb5bF71B9e5257b01F19c66',
      svXZK180d: '0x7646ef7Ea0E3942Aa41D31038a0985458f9dFc3f',
      svXZK90d: '0x4572290F62272397F05aa94A05f10134Bb5Da09D',
      svXZKFlex: '0x96B72dc97B4646Ba2A3ba6679e7378dCE1ecDBc6',
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
