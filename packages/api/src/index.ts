import type { PopulatedTransaction, } from 'ethers';
import { XZKStakingErrorCode, XZKStakingError } from './error';

export type TokenName = 'XZK' | 'VXZK';
export type StakingPeriod = '365d' | '180d' | '90d' | 'Flex';

export interface InitOptions {
    chainId?: number;
    scanApiBaseUrl?: string;
}

export interface ClientOptions {
    tokenName: TokenName;
    stakingPeriod: StakingPeriod;
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
    tokenApprove(options: ClientOptions, account: string, amount: number): Promise<PopulatedTransaction | undefined>;
    stake(options: ClientOptions, account: string, amount: number): Promise<PopulatedTransaction>;
    unstake(options: ClientOptions, account: string, amount: number, nonces: number[]): Promise<PopulatedTransaction>;
    claim(options: ClientOptions, to?: string): Promise<PopulatedTransaction>;
}

export { XZKStakingErrorCode, XZKStakingError };
export { default } from './api';
