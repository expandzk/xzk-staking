import { PopulatedTransaction } from 'ethers';
import { ContractClient } from './client';
import { ClientContext } from './client/context';
import { clientOptionToKey, GlobalClientOptions } from './config/config';
import { createErrorPromise } from './error';

// Import types directly to avoid circular dependency
export type TokenName = 'XZK' | 'VXZK';
export type StakingPeriod = '365d' | '180d' | '90d' | 'Flex';

export interface ClientOptions {
  tokenName: TokenName;
  stakingPeriod: StakingPeriod;
}

export interface InitOptions {
  chainId?: number;
  scanApiBaseUrl?: string;
}

export interface StakingSummary {
  nonce: number;
  totalStaked: number;
  totalCanUnstake: number;
  records: StakingRecord[];
}

export interface StakingRecord {
  stakedTime: number;
  amount: number;
  remaining: number;
}

export interface ClaimSummary {
  unstakeTime: number;
  amount: number;
  claimable: boolean;
  paused: boolean;
}

export interface IStakingClient {
  initialize(options: InitOptions): void;
  readonly isInitialized: boolean;
  resetInitStatus(): void;
  getChainId(options: ClientOptions): Promise<number>;
  tokenContractAddress(options: ClientOptions): Promise<string>;
  stakingContractAddress(options: ClientOptions): Promise<string>;
  stakingStartTimestamp(options: ClientOptions): Promise<number>;
  totalDurationSeconds(options: ClientOptions): Promise<number>;
  stakingPeriodSeconds(options: ClientOptions): Promise<number>;
  claimDelaySeconds(options: ClientOptions): Promise<number>;
  isStakingPaused(options: ClientOptions): Promise<boolean>;
  totalStaked(options: ClientOptions): Promise<number>;
  totalUnstaked(options: ClientOptions): Promise<number>;
  stakingTotalSupply(options: ClientOptions): Promise<number>;
  currentTotalReward(options: ClientOptions): Promise<number>;
  tokenBalance(options: ClientOptions, account: string): Promise<number>;
  stakingBalance(options: ClientOptions, account: string): Promise<number>;
  swapToStakingToken(options: ClientOptions, amount: number): Promise<number>;
  swapToUnderlyingToken(options: ClientOptions, amount: number): Promise<number>;
  stakingSummary(options: ClientOptions, account: string): Promise<StakingSummary>;
  claimSummary(options: ClientOptions, account: string): Promise<ClaimSummary>;
  tokenApprove(
    options: ClientOptions,
    account: string,
    amount: number,
  ): Promise<PopulatedTransaction | undefined>;
  stake(options: ClientOptions, account: string, amount: number): Promise<PopulatedTransaction>;
  unstake(
    options: ClientOptions,
    account: string,
    amount: number,
    nonces: number[],
  ): Promise<PopulatedTransaction>;
  claim(options: ClientOptions): Promise<PopulatedTransaction>;
}

class StakingApiClient implements StakingApiClient {
  private clients: Map<string, ContractClient>;

  private initStatus: boolean = false;

  constructor() {
    this.clients = new Map<string, ContractClient>();
  }

  public initialize(options: InitOptions): void {
    if (this.initStatus) {
      return;
    }

    const context = new ClientContext(options);
    GlobalClientOptions.forEach((clientOption) => {
      const client = new ContractClient(context, clientOption);
      const keyName = clientOptionToKey(clientOption);
      this.clients.set(keyName, client);
    });
    this.initStatus = true;
  }

  public get isInitialized(): boolean {
    return this.initStatus;
  }

  public resetInitStatus(): void {
    this.initStatus = false;
  }

  public getChainId(options: ClientOptions): Promise<number> {
    return this.getClient(options)
      .getChainId()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public tokenContractAddress(options: ClientOptions): Promise<string> {
    return this.getClient(options)
      .tokenContractAddress()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingContractAddress(options: ClientOptions): Promise<string> {
    return this.getClient(options)
      .stakingContractAddress()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingStartTimestamp(options: ClientOptions): Promise<number> {
    return this.getClient(options)
      .stakingStartTimestamp()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public totalDurationSeconds(options: ClientOptions): Promise<number> {
    return this.getClient(options)
      .totalDurationSeconds()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingPeriodSeconds(options: ClientOptions): Promise<number> {
    return this.getClient(options)
      .stakingPeriodSeconds()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public claimDelaySeconds(options: ClientOptions): Promise<number> {
    return this.getClient(options)
      .claimDelaySeconds()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public isStakingPaused(options: ClientOptions): Promise<boolean> {
    return this.getClient(options)
      .isStakingPaused()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public totalStaked(options: ClientOptions): Promise<number> {
    return this.getClient(options)
      .totalStaked()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public totalUnstaked(options: ClientOptions): Promise<number> {
    return this.getClient(options)
      .totalUnstaked()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingTotalSupply(options: ClientOptions): Promise<number> {
    return this.getClient(options)
      .stakingTotalSupply()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public currentTotalReward(options: ClientOptions): Promise<number> {
    return this.getClient(options)
      .currentTotalReward()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public tokenBalance(options: ClientOptions, account: string): Promise<number> {
    return this.getClient(options)
      .tokenBalance(account)
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingBalance(options: ClientOptions, account: string): Promise<number> {
    return this.getClient(options)
      .stakingBalance(account)
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public swapToStakingToken(options: ClientOptions, amount: number): Promise<number> {
    return this.getClient(options)
      .swapToStakingToken(amount)
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public swapToUnderlyingToken(options: ClientOptions, amount: number): Promise<number> {
    return this.getClient(options)
      .swapToUnderlyingToken(amount)
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingSummary(options: ClientOptions, account: string): Promise<StakingSummary> {
    return this.getClient(options)
      .stakingSummary(account)
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public claimSummary(options: ClientOptions, account: string): Promise<ClaimSummary> {
    return this.getClient(options)
      .claimSummary(account)
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public tokenApprove(
    options: ClientOptions,
    account: string,
    amount: number,
  ): Promise<PopulatedTransaction | undefined> {
    return this.getClient(options)
      .tokenApprove(account, amount)
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stake(options: ClientOptions, account: string, amount: number): Promise<PopulatedTransaction> {
    return this.getClient(options)
      .stake(account, amount)
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public unstake(
    options: ClientOptions,
    account: string,
    amount: number,
    nonces: number[],
  ): Promise<PopulatedTransaction> {
    return this.getClient(options)
      .unstake(account, amount, nonces)
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public claim(options: ClientOptions): Promise<PopulatedTransaction> {
    return this.getClient(options)
      .claim()
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private getClient(options: ClientOptions): ContractClient {
    const keyName = clientOptionToKey(options);
    const client = this.clients.get(keyName);
    if (!client) {
      throw new Error(`Client not found for options: ${JSON.stringify(options)}`);
    }
    return client;
  }
}

const stakingApiClient = new StakingApiClient();
export default stakingApiClient;
