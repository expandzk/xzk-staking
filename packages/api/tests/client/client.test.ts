import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import stakingApiClient from '../../src/api';
import type { ClientOptions, InitOptions } from '../../src/index';
import { XZKStakingErrorCode } from '../../src/error';
import { GlobalClientOptions } from '../../src/config/config';

// Mock the dependencies
let allowanceCallCount = 0;
jest.mock('@expandzk/xzk-staking-abi', () => ({
  MystikoStakingContractFactory: {
    connect: jest.fn(() => ({
      START_TIME: jest.fn(() => Promise.resolve({ toNumber: () => 123 })),
      isStakingPaused: jest.fn(() => Promise.resolve({ toNumber: () => 0 })),
      totalStaked: jest.fn(() => Promise.resolve({ toString: () => '100000000000000000000' })),
      totalUnstaked: jest.fn(() => Promise.resolve({ toString: () => '10000000000000000000' })),
      currentTotalReward: jest.fn(() => Promise.resolve({ toString: () => '5000000000000000000' })),
      totalSupply: jest.fn(() => Promise.resolve({ toString: () => '100000000000000000000' })),
      balanceOf: jest.fn(() => Promise.resolve({ toString: () => '50000000000000000000' })),
      swapToStakingToken: jest.fn(() => Promise.resolve({ toString: () => '10000000000000000000' })),
      swapToUnderlyingToken: jest.fn(() => Promise.resolve({ toString: () => '10000000000000000000' })),
      stakingNonces: jest.fn(() => Promise.resolve({ toNumber: () => 2 })),
      stakingRecords: jest.fn(() => Promise.resolve({
        stakedTime: { toNumber: () => 1 },
        amount: { toString: () => '2000000000000000000' },
        remaining: { toString: () => '3000000000000000000' }
      })),
      claimRecords: jest.fn(() => Promise.resolve({
        unstakeTime: { toNumber: () => 1 },
        amount: { toString: () => '2000000000000000000' },
        claimPaused: false
      })),
      populateTransaction: {
        stake: jest.fn(() => Promise.resolve({ gasLimit: { toString: () => '120000' } })),
        unstake: jest.fn(() => Promise.resolve({ gasLimit: { toString: () => '120000' } })),
        claim: jest.fn(() => Promise.resolve({ gasLimit: { toString: () => '120000' } })),
      },
    })),
  },
  ERC20ContractFactory: {
    connect: jest.fn(() => ({
      balanceOf: jest.fn(() => Promise.resolve({ toString: () => '100000000000000000000' })),
      allowance: jest.fn(() => Promise.resolve({
        toString: () => '0',
        gte: jest.fn(() => false), // always require approval
        lt: jest.fn(() => true),
        gt: jest.fn(() => false),
      })),
      populateTransaction: {
        approve: jest.fn(() => Promise.resolve({ gasLimit: { toString: () => '120000' } })),
      },
    })),
  },
}));

jest.mock('@mystikonetwork/utils', () => ({
  DefaultProviderFactory: jest.fn().mockImplementation(() => ({
    createProvider: jest.fn(() => ({})),
  })),
  fromDecimals: jest.fn((value: any, decimals: number) => {
    // Mock implementation that returns a reasonable number
    return parseFloat(value.toString()) / Math.pow(10, decimals);
  }),
  toBN: jest.fn((value: any) => ({
    toString: () => value.toString(),
    gte: jest.fn(() => false), // false for allowance checks
    lt: jest.fn(() => false), // false to make allowance sufficient
    gt: jest.fn(() => false),
  })),
  toDecimals: jest.fn((value: number, decimals: number) => ({
    gt: jest.fn(() => false),
    gte: jest.fn(() => true),
    lt: jest.fn(() => false),
    toString: () => (value * Math.pow(10, decimals)).toString()
  })),
}));

describe('StakingApiClient', () => {
  // Use the actual options from GlobalClientOptions
  const testOptions: ClientOptions = GlobalClientOptions[0]; // { tokenName: 'XZK', stakingPeriod: '365d' }
  const vxzkOptions: ClientOptions = GlobalClientOptions[3]; // { tokenName: 'VXZK', stakingPeriod: '180d' }
  const testInitOptions: InitOptions = { chainId: 1 };

  beforeEach(() => {
    // Reset the client before each test
    stakingApiClient.resetInitStatus();
    // Clear all mocks
    jest.clearAllMocks();
    allowanceCallCount = 0;
  });

  it('should not be initialized by default', () => {
    expect(stakingApiClient.isInitialized).toBe(false);
  });

  it('should initialize and set isInitialized', () => {
    stakingApiClient.initialize(testInitOptions);
    expect(stakingApiClient.isInitialized).toBe(true);
  });

  it('should reset initialization status', () => {
    stakingApiClient.initialize(testInitOptions);
    expect(stakingApiClient.isInitialized).toBe(true);

    stakingApiClient.resetInitStatus();
    expect(stakingApiClient.isInitialized).toBe(false);
  });

  it('should return correct values for initialized client', async () => {
    stakingApiClient.initialize(testInitOptions);

    expect(stakingApiClient.isInitialized).toBe(true);
    expect(await stakingApiClient.getChainId(testOptions)).toBe(1);
    expect(await stakingApiClient.tokenContractAddress(testOptions)).toBeDefined();
    expect(await stakingApiClient.stakingContractAddress(testOptions)).toBeDefined();
    expect(await stakingApiClient.stakingStartTimestamp(testOptions)).toBe(123);
    expect(await stakingApiClient.totalDurationSeconds(testOptions)).toBeDefined();
    expect(await stakingApiClient.stakingPeriodSeconds(testOptions)).toBeDefined();
    expect(await stakingApiClient.claimDelaySeconds(testOptions)).toBeDefined();
    expect(await stakingApiClient.isStakingPaused(testOptions)).toBe(0);
    expect(await stakingApiClient.totalStaked(testOptions)).toBeDefined();
    expect(await stakingApiClient.totalUnstaked(testOptions)).toBeDefined();
    expect(await stakingApiClient.stakingTotalSupply(testOptions)).toBeDefined();
    expect(await stakingApiClient.currentTotalReward(testOptions)).toBeDefined();
    expect(await stakingApiClient.tokenBalance(testOptions, '0x')).toBeDefined();
    expect(await stakingApiClient.stakingBalance(testOptions, '0x')).toBeDefined();
    expect(await stakingApiClient.swapToStakingToken(testOptions, 1)).toBeDefined();
    expect(await stakingApiClient.swapToUnderlyingToken(testOptions, 1)).toBeDefined();

    // Test stakingSummary returns the expected structure
    const stakingSummary = await stakingApiClient.stakingSummary(testOptions, '0x');
    expect(stakingSummary).toHaveProperty('nonce');
    expect(stakingSummary).toHaveProperty('totalStaked');
    expect(stakingSummary).toHaveProperty('totalCanUnstake');
    expect(stakingSummary).toHaveProperty('records');
    expect(Array.isArray(stakingSummary.records)).toBe(true);

    // Test claimSummary returns the expected structure
    const claimSummary = await stakingApiClient.claimSummary(testOptions, '0x');
    expect(claimSummary).toHaveProperty('unstakeTime');
    expect(claimSummary).toHaveProperty('amount');
    expect(claimSummary).toHaveProperty('claimable');
    expect(claimSummary).toHaveProperty('paused');

    // Test transaction methods return PopulatedTransaction objects
    const approveTx = await stakingApiClient.tokenApprove(testOptions, '0x', 1);
    expect(approveTx).toBeDefined();

    const stakeTx = await stakingApiClient.stake(testOptions, '0x', 1);
    expect(stakeTx).toBeDefined();

    const unstakeTx = await stakingApiClient.unstake(testOptions, '0x', 1, [1]);
    expect(unstakeTx).toBeDefined();

    const claimTx = await stakingApiClient.claim(testOptions);
    expect(claimTx).toBeDefined();
  });

  it('should work with different client options', async () => {
    stakingApiClient.initialize(testInitOptions);

    expect(await stakingApiClient.getChainId(vxzkOptions)).toBe(1);
    expect(await stakingApiClient.tokenContractAddress(vxzkOptions)).toBeDefined();
    expect(await stakingApiClient.stakingContractAddress(vxzkOptions)).toBeDefined();
  });

  it('should throw error for unsupported client options', async () => {
    stakingApiClient.initialize(testInitOptions);

    const unsupportedOptions: ClientOptions = { tokenName: 'XZK', stakingPeriod: '999d' as any };

    try {
      await stakingApiClient.getChainId(unsupportedOptions);
      // If we reach here, the test should fail
      expect(true).toBe(false);
    } catch (error: any) {
      expect(error.message).toContain('Client not found for options');
    }
  });
});
