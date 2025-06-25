import { MystikoStaking } from '@expandzk/xzk-staking-abi';
import { fromDecimals, toBN, toDecimals } from '@mystikonetwork/utils';
import { BigNumber, PopulatedTransaction } from 'ethers';
import BN from 'bn.js';
import { createErrorPromise, XZKStakingErrorCode } from '../error';
import type { StakingSummary, StakingRecord, ClaimSummary } from '../index';
import { ClientContext } from './context';
import { ClientOptions } from '..';
import { MystikoStakingContractFactory } from '@expandzk/xzk-staking-abi';

export class ContractClient {
  private options: ClientOptions;

  private context: ClientContext;

  private stakingInstance: MystikoStaking;

  public constructor(context: ClientContext, options: ClientOptions) {
    this.context = context;
    this.options = options;
    const stakingContractAddress = this.context.config.stakingContractAddress(this.options);
    this.stakingInstance = MystikoStakingContractFactory.connect<MystikoStaking>('MystikoStaking', stakingContractAddress, this.context.provider);
  }

  public getChainId(): Promise<number> {
    return Promise.resolve(this.context.config.chainId);
  }

  public tokenContractAddress(): Promise<string> {
    return Promise.resolve(this.context.config.tokenContractAddress(this.options));
  }

  public stakingContractAddress(): Promise<string> {
    return Promise.resolve(this.context.config.stakingContractAddress(this.options));
  }

  public stakingStartTimestamp(): Promise<number> {
    return this.stakingInstance
      .START_TIME()
      .then((timestamp: any) => timestamp.toNumber())
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public totalDurationSeconds(): Promise<number> {
    return Promise.resolve(this.context.config.totalDurationSeconds());
  }

  public stakingPeriodSeconds(): Promise<number> {
    return Promise.resolve(this.context.config.stakingPeriodSeconds(this.options.stakingPeriod));
  }

  public claimDelaySeconds(): Promise<number> {
    return Promise.resolve(this.context.config.claimDelaySeconds());
  }

  public isStakingPaused(): Promise<boolean> {
    return this.stakingInstance
      .isStakingPaused()
      .then((paused: any) => paused.toNumber())
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public totalStaked(): Promise<number> {
    return this.stakingInstance
      .totalStaked()
      .then((totalStaked: any) => fromDecimals(totalStaked, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public totalUnstaked(): Promise<number> {
    return this.stakingInstance
      .totalUnstaked()
      .then((totalUnstaked: any) => fromDecimals(totalUnstaked, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public currentTotalReward(): Promise<number> {
    return this.stakingInstance
      .currentTotalReward()
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public tokenBalance(account: string): Promise<number> {
    const tokenContract = this.context.tokenContractAddress(this.options);
    return tokenContract
      .balanceOf(account)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingTotalSupply(): Promise<number> {
    return this.stakingInstance
      .totalSupply()
      .then((totalSupply: any) => fromDecimals(toBN(totalSupply.toString()), this.context.config.decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingBalance(account: string): Promise<number> {
    return this.stakingInstance
      .balanceOf(account)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public swapToStakingToken(amount: number): Promise<number> {
    return this.stakingInstance
      .swapToStakingToken(amount)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public swapToUnderlyingToken(amount: number): Promise<number> {
    return this.stakingInstance
      .swapToUnderlyingToken(amount)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public stakingSummary(account: string): Promise<StakingSummary> {
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
    const claimDelaySeconds = this.context.config.claimDelaySeconds();
    return this.stakingInstance
      .claimRecords(account)
      .then((record: any) => {
        const claimable = record.unstakeTime.toNumber() + claimDelaySeconds < Date.now() / 1000;
        return {
          unstakeTime: record.unstakeTime.toNumber(),
          amount: fromDecimals(record.amount, this.context.config.decimals),
          claimable,
          paused: record.claimPaused,
        };
      })
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public tokenApprove(account: string, amount: number): Promise<PopulatedTransaction | undefined> {
    return this.tokenBalance(account).then((balance) => {
      const amountBN = toDecimals(amount, this.context.config.decimals);
      const balanceBN = toDecimals(balance, this.context.config.decimals);
      if (amountBN.gt(balanceBN)) {
        return createErrorPromise('Insufficient balance', XZKStakingErrorCode.BALANCE_ERROR);
      }
      return this.buildApproveTransaction(account, amountBN);
    });
  }

  public stake(account: string, amount: number): Promise<PopulatedTransaction> {
    return this.tokenBalance(account).then((balance) => {
      const amountBN = toDecimals(amount, this.context.config.decimals);
      const balanceBN = toDecimals(balance, this.context.config.decimals);
      if (amountBN.gt(balanceBN)) {
        return createErrorPromise('Insufficient balance', XZKStakingErrorCode.BALANCE_ERROR);
      }
      return this.buildStakeTransaction(account, amountBN);
    });
  }

  public unstake(account: string, amount: number, nonces: number[]): Promise<PopulatedTransaction> {
    return this.stakingBalance(account).then((balance) => {
      const amountBN = toDecimals(amount, this.context.config.decimals);
      const balanceBN = toDecimals(balance, this.context.config.decimals);
      if (amountBN.gt(balanceBN)) {
        return createErrorPromise('Insufficient balance', XZKStakingErrorCode.BALANCE_ERROR);
      }
      return this.buildUnstakeTransaction(account, amountBN, nonces);
    });
  }

  public claim(to?: string): Promise<PopulatedTransaction> {
    return this.buildClaimTransaction(to);
  }

  private checkApprove(account: string, amount: BN): Promise<void> {
    return this.tokenAllowance(account).then((allowance) => {
      if (allowance.lt(amount)) {
        return createErrorPromise('Insufficient approve amount', XZKStakingErrorCode.APPROVE_AMOUNT_ERROR);
      }
      return Promise.resolve();
    });
  }

  private tokenAllowance(account: string): Promise<BN> {
    const tokenContract = this.context.tokenContractAddress(this.options);
    const stakingContractAddress = this.context.config.stakingContractAddress(this.options);
    return tokenContract
      .allowance(account, stakingContractAddress)
      .then((allowance: any) => toBN(allowance.toString()))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private buildApproveTransaction(account: string, amount: BN): Promise<PopulatedTransaction | undefined> {
    const tokenContract = this.context.tokenContractAddress(this.options);
    const stakingContractAddress = this.context.config.stakingContractAddress(this.options);
    return this.tokenAllowance(account).then((allowance) => {
      if (allowance.gte(amount)) {
        return Promise.resolve(undefined);
      }
      return tokenContract.populateTransaction
        .approve(stakingContractAddress, amount.toString())
        .catch((error: any) => createErrorPromise(error.toString()));
    });
  }

  private buildStakeTransaction(account: string, amount: BN): Promise<PopulatedTransaction> {
    return this.checkApprove(account, amount)
      .then(() => this.stakingInstance.populateTransaction.stake(amount.toString()))
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
    return this.stakingInstance.populateTransaction
      .unstake(amount.toString(), nonces)
      .then((result: any) => {
        // TODO: to be optimized
        result.gasLimit = BigNumber.from(120000);
        return result;
      })
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private buildClaimTransaction(to?: string): Promise<PopulatedTransaction> {
    // todo add to
    return this.stakingInstance.populateTransaction
      .claim()
      .then(() => this.stakingInstance.populateTransaction.claim())
      .then((result: any) => {
        // TODO: to be optimized
        result.gasLimit = BigNumber.from(120000);
        return result;
      })
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private stakingNonce(account: string): Promise<number> {
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
    return this.stakingInstance
      .stakingRecords(account, index)
      .then((record: any) => ({
        stakedTime: record.stakedTime.toNumber(),
        amount: fromDecimals(record.amount, this.context.config.decimals),
        remaining: fromDecimals(record.remaining, this.context.config.decimals),
      }))
      .catch((error: any) => createErrorPromise(error.toString()));
  }
}

