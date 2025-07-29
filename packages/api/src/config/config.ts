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
      sXZK365d: '0x6747b00A1bd8f8a69a7E21BEAe91C56F5C6E9f8b',
      sXZK180d: '0x2a9aBB08339D5997F4bDf55F95Fb07fF7259321E',
      sXZK90d: '0x796a5DAdeBC516ADAcDFb486B206897B839e9200',
      sXZKFlex: '0x658Be9862A9824E68faE7c3f3E4A86417B8FcA4b',
      svXZK365d: '0xd06e93B227c33afb651871aa7eCc621A3F93e5E0',
      svXZK180d: '0x33Bc3b90f7043a09a441eEa1afaDF5417df39A52',
      svXZK90d: '0xadf9DFA914b02e128b40A8ADc823eabd5b8C81DB',
      svXZKFlex: '0x58c4C6DCD4f9bC5fd23524aE00470bcc0F621999',
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
