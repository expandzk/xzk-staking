import { XzkStaking, MystikoStakingContractFactory } from '@expandzk/xzk-staking-abi';
import { fromDecimals, toBN, toDecimals } from '@mystikonetwork/utils';
import { BigNumber, PopulatedTransaction } from 'ethers';
import BN from 'bn.js';
import { createErrorPromise, XZKStakingErrorCode } from '../error';
import type {
  StakingSummary,
  StakingRecord,
  UnstakingSummary,
  UnstakingRecord,
  ClientOptions,
  ClaimSummary,
} from '../api';
import { ClientContext } from './context';

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
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public totalStaked(): Promise<number> {
    return this.stakingInstance
      .totalStaked()
      .then((totalStaked: any) => fromDecimals(totalStaked, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public totalUnstaked(): Promise<number> {
    return this.stakingInstance
      .totalUnstaked()
      .then((totalUnstaked: any) => fromDecimals(totalUnstaked, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public totalClaimed(): Promise<number> {
    return this.stakingInstance
      .totalClaimed()
      .then((totalClaimed: any) => fromDecimals(totalClaimed, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public estimatedApy(amount?: number): Promise<number> {
    const amountBN = toDecimals(amount || 1e18, this.context.config.decimals);
    return this.stakingInstance.estimatedApy(amountBN.toString()).then((apy: any) => {
      const apyValue = fromDecimals(apy, 18);
      return Math.round(apyValue * 100 * 1000) / 1000;
    });
  }

  public stakerApy(): Promise<number> {
    return this.stakingInstance.stakerApy().then((apy: any) => {
      const apyValue = fromDecimals(apy, 18);
      return Math.round(apyValue * 100 * 1000) / 1000;
    });
  }

  public totalRewardAt(timestamp_seconds?: number): Promise<number> {
    const timestamp = timestamp_seconds || Date.now() / 1000;
    return this.stakingInstance
      .totalRewardAt(timestamp.toString())
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public tokenBalance(account: string): Promise<number> {
    const tokenContract = this.context.tokenContractInstance(this.options);
    return tokenContract
      .balanceOf(account)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
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
      .then((totalSupply: any) => fromDecimals(toBN(totalSupply.toString()), this.context.config.decimals))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public stakingBalance(account: string): Promise<number> {
    return this.stakingInstance
      .balanceOf(account)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public stakingBalanceBN(account: string): Promise<BN> {
    return this.stakingInstance
      .balanceOf(account)
      .then((balance: any) => toBN(balance.toString()))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public swapToStakingToken(amount: number): Promise<number> {
    return this.stakingInstance
      .swapToStakingToken(amount)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
      .catch((error: any) => createErrorPromise(XZKStakingErrorCode.PROVIDER_ERROR, error.toString()));
  }

  public swapToUnderlyingToken(amount: number): Promise<number> {
    return this.stakingInstance
      .swapToUnderlyingToken(amount)
      .then((balance: any) => fromDecimals(balance, this.context.config.decimals))
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
            }
          }
          return {
            totalTokenAmount,
            totalStakingTokenAmount,
            totalStakingTokenRemaining,
            totalCanUnstakeAmount,
            totalCanUnstakeAmountBN,
            records,
          };
        }),
      )
      .catch((error) => createErrorPromise(error.toString()));
  }

  public unstakingSummary(account: string): Promise<UnstakingSummary> {
    return this.unstakingNonce(account)
      .then((nonce) => this.unstakingRecords(account, nonce))
      .then((records) => {
        const totalTokenAmount = records.reduce((acc, record) => acc + record.tokenAmount, 0);
        const totalStakingTokenAmount = records.reduce((acc, record) => acc + record.stakingTokenAmount, 0);
        const totalTokenRemaining = records.reduce((acc, record) => acc + record.tokenRemaining, 0);

        const claimDelaySeconds = this.context.config.claimDelaySeconds();
        let totalCanClaimAmount = 0;
        let totalCanClaimAmountBN = new BN(0);
        const currentTimestamp = Date.now() / 1000;
        for (let i = 0; i < records.length; i += 1) {
          if (currentTimestamp > records[i].unstakedTime + claimDelaySeconds) {
            totalCanClaimAmount += records[i].tokenRemaining;
            totalCanClaimAmountBN = totalCanClaimAmountBN.add(records[i].tokenRemainingBN);
          }
        }
        return {
          totalTokenAmount,
          totalStakingTokenAmount,
          totalTokenRemaining,
          totalCanClaimAmount,
          totalCanClaimAmountBN,
          records,
        };
      })
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  public claimSummary(account: string): Promise<ClaimSummary> {
    // TODO: implement
    return Promise.resolve({
      totalClaimedAmount: 0,
      totalTokenRemaining: 0,
      records: [],
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
          return createErrorPromise(XZKStakingErrorCode.AMOUNT_TOO_LARGE_ERROR);
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
          return createErrorPromise(XZKStakingErrorCode.AMOUNT_TOO_LARGE_ERROR);
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
        return createErrorPromise(XZKStakingErrorCode.AMOUNT_TOO_LARGE_ERROR);
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
        // TODO: to be optimized
        result.gasLimit = BigNumber.from(120000);
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
        // TODO: to be optimized
        result.gasLimit = BigNumber.from(120000);
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
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private stakingNonce(account: string): Promise<number> {
    return this.stakingInstance
      .stakingNonces(account)
      .then((nonce: any) => nonce.toNumber())
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private unstakingNonce(account: string): Promise<number> {
    return this.stakingInstance
      .unstakingNonces(account)
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

  private unstakingRecords(account: string, nonce: number): Promise<UnstakingRecord[]> {
    const promises = [];
    for (let i = 0; i < nonce; i += 1) {
      promises.push(this.unstakingRecord(account, i));
    }
    return Promise.all(promises);
  }

  private stakingRecord(account: string, index: number): Promise<StakingRecord> {
    return this.stakingInstance
      .stakingRecords(account, index)
      .then((record: any) => ({
        stakedTime: record.stakedTime.toNumber(),
        tokenAmount: fromDecimals(record.tokenAmount, this.context.config.decimals),
        stakingTokenAmount: fromDecimals(record.stakingTokenAmount, this.context.config.decimals),
        stakingTokenRemaining: fromDecimals(record.stakingTokenRemaining, this.context.config.decimals),
        stakingTokenRemainingBN: toBN(record.stakingTokenRemaining.toString()),
      }))
      .catch((error: any) => createErrorPromise(error.toString()));
  }

  private unstakingRecord(account: string, index: number): Promise<UnstakingRecord> {
    return this.stakingInstance
      .unstakingRecords(account, index)
      .then((record: any) => ({
        unstakedTime: record.unstakedTime.toNumber(),
        claimTime: record.claimTime.toNumber(),
        stakingTokenAmount: fromDecimals(record.stakingTokenAmount, this.context.config.decimals),
        tokenAmount: fromDecimals(record.tokenAmount, this.context.config.decimals),
        tokenRemaining: fromDecimals(record.tokenRemaining, this.context.config.decimals),
        tokenRemainingBN: toBN(record.tokenRemaining.toString()),
      }))
      .catch((error: any) => createErrorPromise(error.toString()));
  }
}
