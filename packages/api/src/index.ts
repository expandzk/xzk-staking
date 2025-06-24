import type { PopulatedTransaction, providers } from 'ethers';
import Client from './client';
import { XZKStakingErrorCode, XZKStakingError } from './error';

export type StakingContractName =
    | 'sXZK365d'
    | 'sXZK180d'
    | 'sXZK90d'
    | 'sXZKFlex'
    | 'sVXZK365d'
    | 'sVXZK180d'
    | 'sVXZK90d'
    | 'sVXZKFlex';

export interface InitOptions {
    stakingContractName: StakingContractName;
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
    getChainId(): Promise<number>;
    tokenContractAddress(): Promise<string>;
    stakingContractAddress(): Promise<string>;
    stakingStartTimestamp(): Promise<number>;
    totalDurationSeconds(): Promise<number>;
    stakingPeriodSeconds(): Promise<number>;
    claimDelaySeconds(): Promise<number>;
    isStakingPaused(): Promise<boolean>;
    totalStaked(): Promise<number>;
    totalUnstaked(): Promise<number>;
    stakingTotalSupply(): Promise<number>;
    currentTotalReward(): Promise<number>;
    tokenBalance(account: string): Promise<number>;
    stakingBalance(account: string): Promise<number>;
    swapToStakingToken(amount: number): Promise<number>;
    swapToUnderlyingToken(amount: number): Promise<number>;
    stakingSummary(account: string): Promise<StakingSummary>;
    claimSummary(account: string): Promise<ClaimSummary>;
    tokenApprove(account: string, amount: number): Promise<PopulatedTransaction | undefined>;
    stake(account: string, amount: number): Promise<PopulatedTransaction>;
    unstake(account: string, amount: number, nonces: number[]): Promise<PopulatedTransaction>;
    claim(): Promise<PopulatedTransaction>;
}

export { Client, XZKStakingErrorCode, XZKStakingError };
export { default } from './client';
