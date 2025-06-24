import { ERC20, MystikoStaking } from '@expandzk/xzk-staking-abi';
import { DefaultProviderFactory, fromDecimals, toBN, toDecimals } from '@mystikonetwork/utils';
import { BigNumber, PopulatedTransaction, providers } from 'ethers';
import BN from 'bn.js';
import { Config } from './config';
import { createErrorPromise, XZKStakingErrorCode } from './error';
import type { IStakingClient, InitOptions, StakingSummary, StakingRecord, ClaimSummary, StakingContractName } from './index';

export class Client implements IStakingClient {
  private config?: Config;

  private name?: StakingContractName;

  private tokenInstance?: ERC20;

  private stakingInstance?: MystikoStaking;

  public provider?: providers.Provider;

  private isInit: boolean = false;

  initialize(options: InitOptions): void {
    if (this.isInit) {
      return;
    }

    const chainId = options?.chainId || 1;
    this.name = options.stakingContractName;
    this.config = new Config(chainId);
    const factory = new DefaultProviderFactory();
    this.provider = factory.createProvider(this.config.providers);
    this.tokenInstance = this.config.tokenContractInstance(this.provider, options.stakingContractName);
    this.stakingInstance = this.config.stakingContractInstance(this.provider, options.stakingContractName);
    this.isInit = true;
  }

  public get isInitialized(): boolean {
    return this.isInit;
  }

  public resetInitStatus(): void {
    this.isInit = false;
  }

  public getChainId(): Promise<number> {
    if (!this.config) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return Promise.resolve(this.config.chainId);
  }

  public tokenContractAddress(): Promise<string> {
    if (!this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return Promise.resolve(this.config.tokenContractAddress(this.name));
  }

  public stakingContractAddress(): Promise<string> {
    if (!this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return Promise.resolve(this.config.stakingContractAddress(this.name));
  }

  public stakingStartTimestamp(): Promise<number> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return this.stakingInstance
      .START_TIME()
      .then((timestamp: any) => timestamp.toNumber())
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public totalDurationSeconds(): Promise<number> {
    if (!this.config) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return Promise.resolve(this.config.totalDurationSeconds());
  }

  public stakingPeriodSeconds(): Promise<number> {
    if (!this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return Promise.resolve(this.config.stakingPeriodSeconds(this.name));
  }

  public claimDelaySeconds(): Promise<number> {
    if (!this.config) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return Promise.resolve(this.config.claimDelaySeconds());
  }

  public isStakingPaused(): Promise<boolean> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return this.stakingInstance
      .isStakingPaused()
      .then((paused: any) => paused.toNumber())
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public totalStaked(): Promise<number> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.stakingInstance
      .totalStaked()
      .then((totalStaked: any) => fromDecimals(totalStaked, decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public totalUnstaked(): Promise<number> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.stakingInstance
      .totalUnstaked()
      .then((totalUnstaked: any) => fromDecimals(totalUnstaked, decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public currentTotalReward(): Promise<number> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.stakingInstance
      .currentTotalReward()
      .then((balance: any) => fromDecimals(balance, decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public tokenBalance(account: string): Promise<number> {
    if (!this.config || !this.tokenInstance) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.tokenInstance
      .balanceOf(account)
      .then((balance: any) => fromDecimals(balance, decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingTotalSupply(): Promise<number> {
    if (!this.stakingInstance || !this.config) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.stakingInstance
      .totalSupply()
      .then((totalSupply: any) => fromDecimals(toBN(totalSupply.toString()), decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingBalance(account: string): Promise<number> {
    if (!this.config || !this.stakingInstance) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.stakingInstance
      .balanceOf(account)
      .then((balance: any) => fromDecimals(balance, decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public swapToStakingToken(amount: number): Promise<number> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.stakingInstance
      .swapToStakingToken(amount)
      .then((balance: any) => fromDecimals(balance, decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public swapToUnderlyingToken(amount: number): Promise<number> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.stakingInstance
      .swapToUnderlyingToken(amount)
      .then((balance: any) => fromDecimals(balance, decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingSummary(account: string): Promise<StakingSummary> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return this.stakingNonce(account)
      .then((nonce) =>
        this.stakingRecords(account, nonce).then((records) => {
          const totalStaked = records.reduce((acc, record) => acc + record.amount, 0);
          const totalCanUnstake = records.reduce((acc, record) => acc + record.remaining, 0);
          return {
            nonce,
            totalStaked,
            totalCanUnstake,
            records,
          };
        }),
      )
      .catch((error) => createErrorPromise(error.toString()));
  }

  public claimSummary(account: string): Promise<ClaimSummary> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    const claimDelaySeconds = this.config.claimDelaySeconds();
    return this.stakingInstance
      .claimRecords(account)
      .then((record: any) => {
        const claimable = record.unstakeTime.toNumber() + claimDelaySeconds < Date.now() / 1000;
        return {
          unstakeTime: record.unstakeTime.toNumber(),
          amount: fromDecimals(record.amount, decimals),
          claimable,
          paused: record.claimPaused,
        };
      })
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public tokenApprove(account: string, amount: number): Promise<PopulatedTransaction | undefined> {
    if (!this.config) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.tokenBalance(account).then((balance) => {
      const amountBN = toDecimals(amount, decimals);
      if (amountBN.gt(toBN(balance))) {
        return createErrorPromise('Insufficient balance', XZKStakingErrorCode.BALANCE_ERROR);
      }
      return this.buildApproveTransaction(account, amountBN);
    });
  }

  public stake(account: string, amount: number): Promise<PopulatedTransaction> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.tokenBalance(account).then((balance) => {
      const amountBN = toDecimals(amount, decimals);
      if (amountBN.gt(toBN(balance))) {
        return createErrorPromise('Insufficient balance', XZKStakingErrorCode.BALANCE_ERROR);
      }
      return this.buildStakeTransaction(account, amountBN);
    });
  }

  public unstake(account: string, amount: number, nonces: number[]): Promise<PopulatedTransaction> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { decimals } = this.config;
    return this.stakingBalance(account).then((balance) => {
      const amountBN = toDecimals(amount, decimals);
      if (amountBN.gt(toBN(balance))) {
        return createErrorPromise('Insufficient balance', XZKStakingErrorCode.BALANCE_ERROR);
      }
      return this.buildUnstakeTransaction(account, amountBN, nonces);
    });
  }

  public claim(): Promise<PopulatedTransaction> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return this.buildClaimTransaction();
  }

  private checkApprove(account: string, amount: BN): Promise<void> {
    if (!this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return this.tokenAllowance(account).then((allowance) => {
      if (allowance < amount) {
        return createErrorPromise('Insufficient approve amount', XZKStakingErrorCode.APPROVE_AMOUNT_ERROR);
      }
      return Promise.resolve();
    });
  }

  private tokenAllowance(account: string): Promise<BN> {
    if (!this.tokenInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const stakingContractAddress = this.config.stakingContractAddress(this.name);
    return this.tokenInstance
      .allowance(account, stakingContractAddress)
      .then((allowance: any) => toBN(allowance.toString()))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private buildApproveTransaction(account: string, amount: BN): Promise<PopulatedTransaction | undefined> {
    if (!this.tokenInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const stakingContractAddress = this.config.stakingContractAddress(this.name);
    const { tokenInstance } = this;
    return this.tokenAllowance(account).then((allowance) => {
      if (allowance.gte(amount)) {
        return Promise.resolve(undefined);
      }
      return tokenInstance.populateTransaction
        .approve(stakingContractAddress, amount.toString())
        .catch((error: any) => createErrorPromise(error.toString()));
    });
  }

  private buildStakeTransaction(account: string, amount: BN): Promise<PopulatedTransaction> {
    if (!this.stakingInstance) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }
    const { stakingInstance } = this;
    return this.checkApprove(account, amount)
      .then(() => stakingInstance.populateTransaction.stake(amount.toString()))
      .then((result) => {
        // TODO: to be optimized
        result.gasLimit = BigNumber.from(120000);
        return result;
      })
      .catch((error) => createErrorPromise(error.toString()));
  }

  private buildUnstakeTransaction(
    account: string,
    amount: BN,
    nonces: number[],
  ): Promise<PopulatedTransaction> {
    if (!this.stakingInstance) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return this.stakingInstance.populateTransaction
      .unstake(amount.toString(), nonces)
      .then((result: any) => {
        // TODO: to be optimized
        result.gasLimit = BigNumber.from(120000);
        return result;
      })
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private buildClaimTransaction(): Promise<PopulatedTransaction> {
    if (!this.stakingInstance) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    const { stakingInstance } = this;
    return stakingInstance.populateTransaction
      .claim()
      .then(() => stakingInstance.populateTransaction.claim())
      .then((result: any) => {
        // TODO: to be optimized
        result.gasLimit = BigNumber.from(120000);
        return result;
      })
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private stakingNonce(account: string): Promise<number> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }

    return this.stakingInstance
      .stakingNonces(account)
      .then((nonce: any) => nonce.toNumber())
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private stakingRecords(account: string, nonce: number): Promise<StakingRecord[]> {
    const promises = [];
    for (let i = 0; i < nonce; i += 1) {
      promises.push(this.stakingRecord(account, i));
    }
    return Promise.all(promises);
  }

  private stakingRecord(account: string, index: number): Promise<StakingRecord> {
    if (!this.stakingInstance || !this.config || !this.name) {
      return createErrorPromise('Client not initialized', XZKStakingErrorCode.NOT_INITIALIZED_ERROR);
    }
    const { decimals } = this.config;

    return this.stakingInstance
      .stakingRecords(account, index)
      .then((record: any) => ({
        stakedTime: record.stakedTime.toNumber(),
        amount: fromDecimals(record.amount, decimals),
        remaining: fromDecimals(record.remaining, decimals),
      }))
      .catch((error: any) => createErrorPromise(error.toString()));
  }
}

const stakingClient = new Client();
export default stakingClient;
