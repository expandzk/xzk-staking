import { PopulatedTransaction } from 'ethers';
import { ContractClient } from './client';
import { ClientContext } from './client/context';
import { clientOptionToKey, GlobalClientOptions } from './config/config';
import { createErrorPromise, XZKStakingErrorCode } from './error';
import BN from 'bn.js';
import { toDecimals } from '@mystikonetwork/utils';

// Import types directly to avoid circular dependency
export type Network = 'ethereum' | 'sepolia' | 'dev';
export type TokenName = 'XZK' | 'VXZK';
export type StakingPeriod = '365d' | '180d' | '90d' | 'Flex';

export interface ClientOptions {
  tokenName: TokenName;
  stakingPeriod: StakingPeriod;
}

export interface InitOptions {
  network?: Network;
  scanApiBaseUrl?: string;
}

export interface StakingSummary {
  totalTokenAmount: number;
  totalStakingTokenAmount: number;
  totalStakingTokenRemaining: number;
  totalCanUnstakeAmount: number;
  totalCanUnstakeAmountBN: BN;
  records: StakingRecord[];
}

export interface StakingRecord {
  stakedTime: number;
  tokenAmount: number;
  stakingTokenAmount: number;
  stakingTokenRemaining: number;
  stakingTokenRemainingBN: BN;
}

export interface UnstakingSummary {
  totalTokenAmount: number;
  totalStakingTokenAmount: number;
  totalTokenRemaining: number;
  totalCanClaimAmount: number;
  totalCanClaimAmountBN: BN;
  records: UnstakingRecord[];
}

export interface UnstakingRecord {
  unstakedTime: number;
  claimTime: number;
  stakingTokenAmount: number;
  tokenAmount: number;
  tokenRemaining: number;
  tokenRemainingBN: BN;
}

export interface ClaimSummary {
  totalClaimedAmount: number;
  totalTokenRemaining: number;
  records: ClaimRecord[];
}

export interface ClaimRecord {
  claimedTime: number;
  claimedAmount: number;
}

export interface IStakingClient {
  initialize(options: InitOptions): void;
  readonly isInitialized: boolean;
  resetInitStatus(): void;
  totalXzkAmountSummary(): Promise<number>;
  totalVxzkAmountSummary(): Promise<number>;
  totalRewardXzkAmountSummary(): Promise<number>;
  totalRewardVxzkAmountSummary(): Promise<number>;
  getChainId(options: ClientOptions): Promise<number>;
  tokenContractAddress(options: ClientOptions): Promise<string>;
  stakingContractAddress(options: ClientOptions): Promise<string>;
  stakingStartTimestamp(options: ClientOptions): Promise<number>;
  totalDurationSeconds(options: ClientOptions): Promise<number>;
  stakingPeriodSeconds(options: ClientOptions): Promise<number>;
  claimDelaySeconds(options: ClientOptions): Promise<number>;
  isStakingPaused(options: ClientOptions): Promise<boolean>;
  poolTokenAmount(options: ClientOptions): Promise<number>;
  stakingTotalSupply(options: ClientOptions): Promise<number>;
  totalStaked(options: ClientOptions): Promise<number>;
  totalUnstaked(options: ClientOptions): Promise<number>;
  totalClaimed(options: ClientOptions): Promise<number>;
  estimatedApy(options: ClientOptions, amount?: number): Promise<number>;
  stakerApy(options: ClientOptions): Promise<number>;
  totalRewardAt(options: ClientOptions, timestamp_seconds?: number): Promise<number>;
  tokenBalance(options: ClientOptions, account: string): Promise<number>;
  stakingBalance(options: ClientOptions, account: string): Promise<number>;
  swapToStakingToken(options: ClientOptions, amount: number): Promise<number>;
  swapToUnderlyingToken(options: ClientOptions, amount: number): Promise<number>;
  stakingSummary(options: ClientOptions, account: string): Promise<StakingSummary>;
  unstakingSummary(options: ClientOptions, account: string): Promise<UnstakingSummary>;
  claimSummary(options: ClientOptions, account: string): Promise<ClaimSummary>;
  tokenApprove(
    options: ClientOptions,
    account: string,
    isMax?: boolean,
    amount?: number,
  ): Promise<PopulatedTransaction | undefined>;
  stake(
    options: ClientOptions,
    account: string,
    isMax?: boolean,
    amount?: number,
  ): Promise<PopulatedTransaction>;
  unstake(
    options: ClientOptions,
    account: string,
    isMax?: boolean,
    amount?: number,
  ): Promise<PopulatedTransaction>;
  claim(options: ClientOptions, account: string, toAccount?: string): Promise<PopulatedTransaction>;
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
    this.clients.clear();
    this.initStatus = false;
  }

  public totalXzkAmountSummary(): Promise<number> {
    const promises: Promise<number>[] = [];
    GlobalClientOptions.forEach((clientOption) => {
      if (clientOption.tokenName === 'XZK') {
        promises.push(this.getClient(clientOption).then((client) => client.poolTokenAmount()));
      }
    });
    return Promise.all(promises).then((results) => {
      return results.reduce((acc, curr) => acc + curr, 0);
    });
  }

  public totalVxzkAmountSummary(): Promise<number> {
    const promises: Promise<number>[] = [];
    GlobalClientOptions.forEach((clientOption) => {
      if (clientOption.tokenName === 'VXZK') {
        promises.push(this.getClient(clientOption).then((client) => client.poolTokenAmount()));
      }
    });
    return Promise.all(promises).then((results) => {
      return results.reduce((acc, curr) => acc + curr, 0);
    });
  }

  public totalRewardXzkAmountSummary(): Promise<number> {
    const promises: Promise<number>[] = [];
    GlobalClientOptions.forEach((clientOption) => {
      if (clientOption.tokenName === 'XZK') {
        promises.push(this.getClient(clientOption).then((client) => client.totalRewardAt()));
      }
    });
    return Promise.all(promises).then((results) => {
      return results.reduce((acc, curr) => acc + curr, 0);
    });
  }

  public totalRewardVxzkAmountSummary(): Promise<number> {
    const promises: Promise<number>[] = [];
    GlobalClientOptions.forEach((clientOption) => {
      if (clientOption.tokenName === 'VXZK') {
        promises.push(this.getClient(clientOption).then((client) => client.totalRewardAt()));
      }
    });
    return Promise.all(promises).then((results) => {
      return results.reduce((acc, curr) => acc + curr, 0);
    });
  }

  public getChainId(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.getChainId());
  }

  public tokenContractAddress(options: ClientOptions): Promise<string> {
    return this.getClient(options).then((client) => client.tokenContractAddress());
  }

  public stakingContractAddress(options: ClientOptions): Promise<string> {
    return this.getClient(options).then((client) => client.stakingContractAddress());
  }

  public stakingStartTimestamp(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.stakingStartTimestamp());
  }

  public totalDurationSeconds(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.totalDurationSeconds());
  }

  public stakingPeriodSeconds(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.stakingPeriodSeconds());
  }

  public claimDelaySeconds(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.claimDelaySeconds());
  }

  public isStakingPaused(options: ClientOptions): Promise<boolean> {
    return this.getClient(options).then((client) => client.isStakingPaused());
  }

  public poolTokenAmount(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.poolTokenAmount());
  }

  public totalStaked(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.totalStaked());
  }

  public totalUnstaked(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.totalUnstaked());
  }

  public totalClaimed(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.totalClaimed());
  }

  public estimatedApy(options: ClientOptions, amount?: number): Promise<number> {
    return this.getClient(options).then((client) => client.estimatedApy(amount));
  }

  public stakerApy(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.stakerApy());
  }

  public stakingTotalSupply(options: ClientOptions): Promise<number> {
    return this.getClient(options).then((client) => client.stakingTotalSupply());
  }

  public totalRewardAt(options: ClientOptions, timestamp_seconds?: number): Promise<number> {
    return this.getClient(options).then((client) => client.totalRewardAt(timestamp_seconds));
  }

  public tokenBalance(options: ClientOptions, account: string): Promise<number> {
    return this.getClient(options).then((client) => client.tokenBalance(account));
  }

  public stakingBalance(options: ClientOptions, account: string): Promise<number> {
    return this.getClient(options).then((client) => client.stakingBalance(account));
  }

  public swapToStakingToken(options: ClientOptions, amount: number): Promise<number> {
    return this.getClient(options).then((client) => client.swapToStakingToken(amount));
  }

  public swapToUnderlyingToken(options: ClientOptions, amount: number): Promise<number> {
    return this.getClient(options).then((client) => client.swapToUnderlyingToken(amount));
  }

  public stakingSummary(options: ClientOptions, account: string): Promise<StakingSummary> {
    return this.getClient(options).then((client) => client.stakingSummary(account));
  }

  public unstakingSummary(options: ClientOptions, account: string): Promise<UnstakingSummary> {
    return this.getClient(options).then((client) => client.unstakingSummary(account));
  }

  public claimSummary(options: ClientOptions, account: string): Promise<ClaimSummary> {
    return this.getClient(options).then((client) => client.claimSummary(account));
  }

  public tokenApprove(
    options: ClientOptions,
    account: string,
    isMax?: boolean,
    amount?: number,
  ): Promise<PopulatedTransaction | undefined> {
    return this.getClient(options).then((client) => client.tokenApprove(account, isMax, amount));
  }

  public stake(
    options: ClientOptions,
    account: string,
    isMax?: boolean,
    amount?: number,
  ): Promise<PopulatedTransaction> {
    return this.getClient(options).then((client) => client.stake(account, isMax, amount));
  }

  public unstake(
    options: ClientOptions,
    account: string,
    isMax?: boolean,
    amount?: number,
  ): Promise<PopulatedTransaction> {
    return this.getClient(options).then((client: ContractClient) =>
      client.stakingSummary(account).then((summary: StakingSummary) => {
        let unstakeAmountBN: BN;
        if (isMax) {
          unstakeAmountBN = summary.totalCanUnstakeAmountBN;
        } else {
          if (amount === undefined) {
            return createErrorPromise(XZKStakingErrorCode.AMOUNT_NOT_SPECIFIED_ERROR);
          }
          unstakeAmountBN = toDecimals(amount, client.getDecimals());
        }
        let startNonce = 0;
        let endNonce = 0;
        let totalCanUnstakeAmountBN = new BN(0);
        for (let i = 0; i < summary.records.length; i += 1) {
          if (summary.records[i].stakingTokenRemaining > 0) {
            if (startNonce === 0) {
              startNonce = i;
            }
            totalCanUnstakeAmountBN = totalCanUnstakeAmountBN.add(summary.records[i].stakingTokenRemainingBN);
            if (totalCanUnstakeAmountBN.gte(unstakeAmountBN)) {
              endNonce = i;
              break;
            }
          }
        }
        return client.unstake(account, unstakeAmountBN, startNonce, endNonce);
      }),
    );
  }

  public claim(options: ClientOptions, account: string, toAccount?: string): Promise<PopulatedTransaction> {
    return this.getClient(options).then((client) =>
      client.unstakingSummary(account).then((summary: UnstakingSummary) => {
        if (summary.totalCanClaimAmount <= 0) {
          return createErrorPromise(XZKStakingErrorCode.NO_CLAIMABLE_AMOUNT_ERROR);
        }
        let startNonce = 0;
        let endNonce = 0;
        let totalCanClaimAmountBN = new BN(0);
        for (let i = 0; i < summary.records.length; i += 1) {
          if (summary.records[i].tokenRemainingBN.gt(new BN(0))) {
            if (startNonce === 0) {
              startNonce = i;
            }
            totalCanClaimAmountBN = totalCanClaimAmountBN.add(summary.records[i].tokenRemainingBN);
            if (totalCanClaimAmountBN.gte(summary.totalCanClaimAmountBN)) {
              endNonce = i;
              break;
            }
          }
        }
        return client.claim(toAccount || account, startNonce, endNonce);
      }),
    );
  }

  private getClient(options: ClientOptions): Promise<ContractClient> {
    const keyName = clientOptionToKey(options);
    const client = this.clients.get(keyName);
    if (!client) {
      return createErrorPromise(XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }
    return Promise.resolve(client);
  }
}

const stakingApiClient = new StakingApiClient();
export default stakingApiClient;
