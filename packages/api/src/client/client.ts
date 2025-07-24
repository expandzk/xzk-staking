import { XzkStaking, MystikoStakingContractFactory } from '@expandzk/xzk-staking-abi';
import { fromDecimals, toBN, toDecimals } from '@mystikonetwork/utils';
import { PopulatedTransaction } from 'ethers';
import BN from 'bn.js';
import { createErrorPromise, XZKStakingErrorCode } from '../error';
import type {
  StakingSummary,
  UnstakingSummary,
  ClientOptions,
  ClaimSummary,
  StakingRecord,
  UnstakingRecord,
  ClaimRecord,
  StakeActionSummary,
  UnstakeActionSummary,
  StakingPoolConfig,
} from '../api';
import { ClientContext } from './context';
import { round } from '../config/config';

export class ContractClient {
  private options: ClientOptions;

  private context: ClientContext;

  private stakingInstance: XzkStaking;

  public constructor(context: ClientContext, options: ClientOptions) {
    this.context = context;
    this.options = options;
    const stakingContractAddress = this.context.config.stakingContractAddress(this.options);
    this.stakingInstance = MystikoStakingContractFactory.connect<XzkStaking>(
      'XzkStaking',
      stakingContractAddress,
      this.context.provider,
    );
  }

  public getStakingPoolConfig(): Promise<StakingPoolConfig> {
    return Promise.resolve({
      chainId: this.context.config.chainId,
      tokenName: this.options.tokenName,
      tokenDecimals: this.context.config.decimals,
      stakingTokenName: this.context.config.stakingTokenName(this.options),
      stakingTokenDecimals: this.context.config.decimals,
      tokenContractAddress: this.context.config.tokenContractAddress(this.options),
      stakingContractAddress: this.context.config.stakingContractAddress(this.options),
      stakingPeriodSeconds: this.context.config.stakingPeriodSeconds(this.options.stakingPeriod),
      totalDurationSeconds: this.context.config.totalDurationSeconds(),
      claimDelaySeconds: this.context.config.claimDelaySeconds(),
    });
  }

  public getChainId(): Promise<number> {
    return Promise.resolve(this.context.config.chainId);
  }

  public getDecimals(): number {
    return this.context.config.decimals;
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
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
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
      .then((paused: any) => Boolean(paused))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public poolTokenAmount(): Promise<number> {
    const tokenContract = this.context.tokenContractInstance(this.options);
    return tokenContract
      .balanceOf(this.context.config.stakingContractAddress(this.options))
      .then((amount: any) => fromDecimals(amount, this.context.config.decimals))
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public totalStaked(): Promise<number> {
    return this.stakingInstance
      .totalStaked()
      .then((totalStaked: any) => fromDecimals(totalStaked, this.context.config.decimals))
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public totalUnstaked(): Promise<number> {
    return this.stakingInstance
      .totalUnstaked()
      .then((totalUnstaked: any) => fromDecimals(totalUnstaked, this.context.config.decimals))
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public totalClaimed(): Promise<number> {
    return this.stakingInstance
      .totalClaimed()
      .then((totalClaimed: any) => fromDecimals(totalClaimed, this.context.config.decimals))
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public estimatedApr(amount?: number): Promise<number> {
    let amountBN: BN;
    if (amount === undefined) {
      amountBN = toDecimals(1, this.context.config.decimals);
    } else {
      amountBN = toDecimals(amount, this.context.config.decimals);
    }
    return this.stakingInstance
      .estimatedApr(amountBN.toString())
      .then((apy: any) => {
        const apyValue = fromDecimals(apy, 18);
        return Math.round(apyValue * 100 * 1000) / 1000;
      })
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public stakerApr(): Promise<number> {
    return this.stakingInstance
      .stakerApr()
      .then((apy: any) => {
        const apyValue = fromDecimals(apy, 18);
        return Math.round(apyValue * 100 * 1000) / 1000;
      })
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public totalRewardAt(timestamp_seconds?: number): Promise<number> {
    const timestamp = timestamp_seconds || Math.floor(Date.now() / 1000);
    return this.stakingInstance
      .totalRewardAt(timestamp.toString())
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public tokenBalance(account: string): Promise<number> {
    const tokenContract = this.context.tokenContractInstance(this.options);
    return tokenContract
      .balanceOf(account)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public tokenBalanceBN(account: string): Promise<BN> {
    const tokenContract = this.context.tokenContractInstance(this.options);
    return tokenContract
      .balanceOf(account)
      .then((balance: any) => toBN(balance.toString()))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public stakingTotalSupply(): Promise<number> {
    return this.stakingInstance
      .totalSupply()
      .then((totalSupply: any) => fromDecimals(totalSupply, this.context.config.decimals))
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public stakingBalance(account: string): Promise<number> {
    return this.stakingInstance
      .balanceOf(account)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public stakingBalanceBN(account: string): Promise<BN> {
    return this.stakingInstance
      .balanceOf(account)
      .then((balance: any) => toBN(balance.toString()))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public swapToStakingToken(amount: number): Promise<number> {
    const amountBN = toDecimals(amount, this.context.config.decimals);
    return this.stakingInstance
      .swapToStakingToken(amountBN.toString())
      .then((stakingAmount: any) => {
        return fromDecimals(stakingAmount, this.context.config.decimals);
      })
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public swapToUnderlyingToken(amount: number): Promise<number> {
    const amountBN = toDecimals(amount, this.context.config.decimals);
    return this.stakingInstance
      .swapToUnderlyingToken(amountBN.toString())
      .then((underlyingAmount: any) => {
        return fromDecimals(underlyingAmount, this.context.config.decimals);
      })
      .then((amount: number) => round(amount))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public stakingSummary(account: string): Promise<StakingSummary> {
    return this.stakingNonce(account)
      .then((nonce) =>
        this.stakingRecords(account, nonce).then((records) => {
          const totalTokenAmount = records.reduce((acc, record) => acc + record.tokenAmount, 0);
          const totalStakingTokenAmount = records.reduce((acc, record) => acc + record.stakingTokenAmount, 0);
          const totalStakingTokenRemaining = records.reduce(
            (acc, record) => acc + record.stakingTokenRemaining,
            0,
          );
          let totalCanUnstakeAmount = 0;
          let totalCanUnstakeAmountBN = new BN(0);
          const currentTimestamp = Date.now() / 1000;
          const stakingPeriodSeconds = this.context.config.stakingPeriodSeconds(this.options.stakingPeriod);
          for (let i = 0; i < records.length; i += 1) {
            if (currentTimestamp > records[i].stakedTime + stakingPeriodSeconds) {
              totalCanUnstakeAmount += records[i].stakingTokenRemaining;
              totalCanUnstakeAmountBN = totalCanUnstakeAmountBN.add(records[i].stakingTokenRemainingBN);
              records[i].canUnstakeAmount = records[i].stakingTokenRemaining;
              records[i].canUnstake = true;
            } else {
              records[i].canUnstake = false;
            }
          }
          return {
            totalTokenAmount: round(totalTokenAmount),
            totalStakingTokenAmount: round(totalStakingTokenAmount),
            totalStakingTokenRemaining: round(totalStakingTokenRemaining),
            totalStakingTokenLocked: round(totalStakingTokenRemaining) - round(totalCanUnstakeAmount),
            totalCanUnstakeAmount: round(totalCanUnstakeAmount),
            totalCanUnstakeAmountBN,
            records,
          };
        }),
      )
      .catch((error) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public unstakingSummary(account: string): Promise<UnstakingSummary> {
    return this.unstakingNonce(account)
      .then((nonce) => this.unstakingRecords(account, nonce))
      .then((records) => {
        const totalTokenAmount = records.reduce((acc, record) => acc + record.tokenAmount, 0);
        const totalStakingTokenAmount = records.reduce((acc, record) => acc + record.unstakingTokenAmount, 0);
        const totalTokenRemaining = records.reduce((acc, record) => acc + record.tokenRemaining, 0);

        const claimDelaySeconds = this.context.config.claimDelaySeconds();
        let totalCanClaimAmount = 0;
        let totalCanClaimAmountBN = new BN(0);
        const currentTimestamp = Date.now() / 1000;
        for (let i = 0; i < records.length; i += 1) {
          if (currentTimestamp > records[i].unstakedTime + claimDelaySeconds) {
            totalCanClaimAmount += records[i].tokenRemaining;
            totalCanClaimAmountBN = totalCanClaimAmountBN.add(records[i].tokenRemainingBN);
            records[i].canClaimAmount = records[i].tokenRemaining;
            records[i].canClaim = true;
          } else {
            records[i].canClaim = false;
          }
        }
        return {
          totalTokenAmount: round(totalTokenAmount),
          totalUnstakingTokenAmount: round(totalStakingTokenAmount),
          totalTokenRemaining: round(totalTokenRemaining),
          totalTokenLocked: round(totalTokenRemaining) - round(totalCanClaimAmount),
          totalCanClaimAmount: round(totalCanClaimAmount),
          totalCanClaimAmountBN,
          records,
        };
      })
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public claimSummary(account: string): Promise<ClaimSummary> {
    return this.unstakingNonce(account)
      .then((nonce) => this.claimRecords(account, nonce))
      .then((records) => {
        const filterRecords = records.filter((record) => record.claimedTime > 0);
        const totalClaimedAmount = filterRecords.reduce((acc, record) => acc + record.claimedAmount, 0);
        return {
          totalClaimedAmount: round(totalClaimedAmount),
          records: filterRecords,
        };
      });
  }

  public stakeActionSummary(amount: number): Promise<StakeActionSummary> {
    const currentTimestamp = Date.now() / 1000;
    const stakingPeriodSeconds = this.context.config.stakingPeriodSeconds(this.options.stakingPeriod);
    const canUnstakeTime = currentTimestamp + stakingPeriodSeconds + 1;
    return this.swapToStakingToken(amount).then((stakingTokenAmount) => {
      return {
        tokenAmount: amount,
        stakingTime: currentTimestamp,
        canUnstakeTime,
        stakingTokenAmount,
      };
    });
  }

  public unstakeActionSummary(amount: number): Promise<UnstakeActionSummary> {
    const currentTimestamp = Date.now() / 1000;
    const claimDelaySeconds = this.context.config.claimDelaySeconds();
    const canClaimTime = currentTimestamp + claimDelaySeconds + 1;
    return this.swapToUnderlyingToken(amount).then((tokenAmount) => {
      return {
        unstakingTokenAmount: amount,
        unstakingTime: currentTimestamp,
        canClaimTime,
        tokenAmount,
      };
    });
  }

  public tokenApprove(
    account: string,
    isMax?: boolean,
    amount?: number,
  ): Promise<PopulatedTransaction | undefined> {
    return this.tokenBalanceBN(account).then((balance) => {
      let amountBN: BN;
      if (isMax) {
        amountBN = balance;
      } else {
        if (amount === undefined) {
          return createErrorPromise(XZKStakingErrorCode.AMOUNT_NOT_SPECIFIED_ERROR);
        }
        amountBN = toDecimals(amount, this.context.config.decimals);
        if (amountBN.gt(balance)) {
          return createErrorPromise(XZKStakingErrorCode.INSUFFICIENT_BALANCE_ERROR);
        }
      }
      return this.buildApproveTransaction(account, amountBN);
    });
  }

  public stake(account: string, isMax?: boolean, amount?: number): Promise<PopulatedTransaction> {
    return this.tokenBalanceBN(account).then((balance) => {
      let amountBN: BN;
      if (isMax) {
        amountBN = balance;
      } else {
        if (amount === undefined) {
          return createErrorPromise(XZKStakingErrorCode.AMOUNT_NOT_SPECIFIED_ERROR);
        }
        amountBN = toDecimals(amount, this.context.config.decimals);
        if (amountBN.gt(balance)) {
          return createErrorPromise(XZKStakingErrorCode.INSUFFICIENT_BALANCE_ERROR);
        }
      }
      return this.buildStakeTransaction(account, amountBN);
    });
  }

  public unstake(
    account: string,
    amountBN: BN,
    startNonce: number,
    endNonce: number,
  ): Promise<PopulatedTransaction> {
    return this.stakingBalanceBN(account).then((balance) => {
      if (amountBN.gt(balance)) {
        return createErrorPromise(XZKStakingErrorCode.INSUFFICIENT_BALANCE_ERROR);
      }
      return this.buildUnstakeTransaction(amountBN, startNonce, endNonce);
    });
  }

  public claim(toAccount: string, startNonce: number, endNonce: number): Promise<PopulatedTransaction> {
    return this.buildClaimTransaction(toAccount, startNonce, endNonce);
  }

  private checkApprove(account: string, amount: BN): Promise<void> {
    return this.tokenAllowance(account).then((allowance) => {
      if (allowance.lt(amount)) {
        return createErrorPromise(XZKStakingErrorCode.APPROVE_AMOUNT_ERROR);
      }
      return Promise.resolve();
    });
  }

  private tokenAllowance(account: string): Promise<BN> {
    const tokenContract = this.context.tokenContractInstance(this.options);
    const stakingContractAddress = this.context.config.stakingContractAddress(this.options);
    return tokenContract
      .allowance(account, stakingContractAddress)
      .then((allowance: any) => toBN(allowance.toString()))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  private buildApproveTransaction(account: string, amount: BN): Promise<PopulatedTransaction | undefined> {
    const tokenContract = this.context.tokenContractInstance(this.options);
    const stakingContractAddress = this.context.config.stakingContractAddress(this.options);
    return this.tokenAllowance(account).then((allowance) => {
      if (allowance.gte(amount)) {
        return Promise.resolve(undefined);
      }
      return tokenContract.populateTransaction
        .approve(stakingContractAddress, amount.toString())
        .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
    });
  }

  private buildStakeTransaction(account: string, amount: BN): Promise<PopulatedTransaction> {
    return this.checkApprove(account, amount)
      .then(() => this.stakingInstance.populateTransaction.stake(amount.toString()))
      .then((result) => {
        if (result.gasLimit) {
          result.gasLimit = result.gasLimit.mul(115).div(100);
        }
        return result;
      })
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  private buildUnstakeTransaction(
    amount: BN,
    startNonce: number,
    endNonce: number,
  ): Promise<PopulatedTransaction> {
    return this.stakingInstance.populateTransaction
      .unstake(amount.toString(), startNonce, endNonce)
      .then((result: any) => {
        if (result.gasLimit) {
          result.gasLimit = result.gasLimit.mul(115).div(100);
        }
        return result;
      })
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  private buildClaimTransaction(
    toAccount: string,
    startNonce: number,
    endNonce: number,
  ): Promise<PopulatedTransaction> {
    return this.stakingInstance.populateTransaction
      .claim(toAccount, startNonce, endNonce)
      .then((result: any) => {
        if (result.gasLimit) {
          result.gasLimit = result.gasLimit.mul(115).div(100);
        }
        return result;
      })
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  private stakingNonce(account: string): Promise<number> {
    return this.stakingInstance
      .stakingNonces(account)
      .then((nonce: any) => nonce.toNumber())
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  private unstakingNonce(account: string): Promise<number> {
    return this.stakingInstance
      .unstakingNonces(account)
      .then((nonce: any) => nonce.toNumber())
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  private stakingRecords(account: string, nonce: number): Promise<StakingRecord[]> {
    const promises = [];
    for (let i = 0; i < nonce; i += 1) {
      promises.push(this.stakingRecord(account, i));
    }
    return Promise.all(promises);
  }

  private unstakingRecords(account: string, nonce: number): Promise<UnstakingRecord[]> {
    const promises = [];
    for (let i = 0; i < nonce; i += 1) {
      promises.push(this.unstakingRecord(account, i));
    }
    return Promise.all(promises);
  }

  private claimRecords(account: string, nonce: number): Promise<ClaimRecord[]> {
    const promises = [];
    for (let i = 0; i < nonce; i += 1) {
      promises.push(this.claimRecord(account, i));
    }
    return Promise.all(promises);
  }

  private stakingRecord(account: string, index: number): Promise<StakingRecord> {
    return this.stakingInstance
      .stakingRecords(account, index)
      .then(
        (record: any) =>
          ({
            stakedTime: record.stakingTime.toNumber(),
            canUnstakeTime:
              record.stakingTime.toNumber() +
              this.context.config.stakingPeriodSeconds(this.options.stakingPeriod),
            tokenAmount: round(fromDecimals(record.tokenAmount, this.context.config.decimals)),
            stakingTokenAmount: round(fromDecimals(record.stakingTokenAmount, this.context.config.decimals)),
            canUnstakeAmount: 0,
            stakingTokenRemaining: round(
              fromDecimals(record.stakingTokenRemaining, this.context.config.decimals),
            ),
            stakingTokenRemainingBN: toBN(record.stakingTokenRemaining.toString()),
          } as StakingRecord),
      )
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  private unstakingRecord(account: string, index: number): Promise<UnstakingRecord> {
    return this.stakingInstance
      .unstakingRecords(account, index)
      .then(
        (record: any) =>
          ({
            unstakedTime: record.unstakingTime.toNumber(),
            canClaimTime: record.unstakingTime.toNumber() + this.context.config.claimDelaySeconds(),
            unstakingTokenAmount: round(
              fromDecimals(record.stakingTokenAmount, this.context.config.decimals),
            ),
            tokenAmount: round(fromDecimals(record.tokenAmount, this.context.config.decimals)),
            canClaimAmount: 0,
            tokenRemaining: round(fromDecimals(record.tokenRemaining, this.context.config.decimals)),
            tokenRemainingBN: toBN(record.tokenRemaining.toString()),
          } as UnstakingRecord),
      )
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  private claimRecord(account: string, index: number): Promise<ClaimRecord> {
    return this.stakingInstance
      .unstakingRecords(account, index)
      .then(
        (record: any) =>
          ({
            claimedTime: record.claimTime.toNumber(),
            claimedAmount: round(fromDecimals(record.tokenAmount, this.context.config.decimals)),
          } as ClaimRecord),
      )
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }
}
