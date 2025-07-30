import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import type { ClientOptions, InitOptions } from '../../../src/index';
import { GlobalClientOptions } from '../../../src/config/config';

// Mock the dependencies
jest.mock('@expandzk/xzk-staking-abi', () => {
  const contractMock = {
    START_TIME: jest.fn(() => Promise.resolve({ toNumber: () => 123 })),
    TOTAL_DURATION_SECONDS: jest.fn(() => Promise.resolve({ toNumber: () => 31536000 })),
    STAKING_PERIOD_SECONDS: jest.fn(() => Promise.resolve({ toNumber: () => 31536000 })),
    CLAIM_DELAY_SECONDS: jest.fn(() => Promise.resolve({ toNumber: () => 86400 })),
    isStakingPaused: jest.fn(() => Promise.resolve(true)),
    totalStaked: jest.fn(() => Promise.resolve({ toString: () => '100000000000000000000' })),
    totalUnstaked: jest.fn(() => Promise.resolve({ toString: () => '10000000000000000000' })),
    totalClaimed: jest.fn(() => Promise.resolve({ toString: () => '5000000000000000000' })),
    totalRewardAt: jest.fn(() => Promise.resolve({ toString: () => '5000000000000000000' })),
    totalSupply: jest.fn(() => Promise.resolve({ toString: () => '100000000000000000000' })),
    balanceOf: jest.fn(() => Promise.resolve({ toString: () => '50000000000000000000' })),
    swapToStakingToken: jest.fn(() => Promise.resolve({ toString: () => '10000000000000000000' })),
    swapToUnderlyingToken: jest.fn(() => Promise.resolve({ toString: () => '10000000000000000000' })),
    estimatedApr: jest.fn(() => Promise.resolve({ toString: () => '50000000000000000' })),
    stakerApr: jest.fn(() => Promise.resolve({ toString: () => '50000000000000000' })),
    stakingNonces: jest.fn(() => Promise.resolve({ toNumber: () => 2 })),
    unstakingNonces: jest.fn(() => Promise.resolve({ toNumber: () => 1 })),
    stakingRecords: jest.fn((account, index) =>
      Promise.resolve({
        stakingTime: { toNumber: () => 0 },
        tokenAmount: { toString: () => '2000000000000000000' },
        stakingTokenAmount: { toString: () => '2000000000000000000' },
        stakingTokenRemaining: { toString: () => '3000000000000000000' },
      }),
    ),
    unstakingRecords: jest.fn((account, index) =>
      Promise.resolve({
        unstakingTime: { toNumber: () => 0 },
        claimTime: { toNumber: () => 2 },
        stakingTokenAmount: { toString: () => '2000000000000000000' },
        tokenAmount: { toString: () => '2000000000000000000' },
        tokenRemaining: { toString: () => '2000000000000000000' },
      }),
    ),
    populateTransaction: {
      stake: jest.fn(() => Promise.resolve({ gasLimit: { toString: () => '120000' } })),
      unstake: jest.fn(() => Promise.resolve({ gasLimit: { toString: () => '120000' } })),
      claim: jest.fn(() => Promise.resolve({ gasLimit: { toString: () => '120000' } })),
    },
  };
  return {
    MystikoStakingContractFactory: {
      connect: jest.fn(() => contractMock),
    },
    ERC20ContractFactory: {
      connect: jest.fn(() => ({
        balanceOf: jest.fn(() => Promise.resolve({ toString: () => '100000000000000000000' })),
        allowance: jest.fn(() =>
          Promise.resolve({
            toString: () => '0',
            gte: jest.fn(() => false),
            lt: jest.fn(() => true),
            gt: jest.fn(() => false),
          }),
        ),
        populateTransaction: {
          approve: jest.fn(() => Promise.resolve({ gasLimit: { toString: () => '120000' } })),
        },
      })),
    },
  };
});

function createMockBN(value: any): any {
  return {
    toString: () => value.toString(),
    gte: jest.fn((other: any) => parseFloat(value.toString()) >= parseFloat(other.toString())),
    lt: jest.fn((other: any) => parseFloat(value.toString()) < parseFloat(other.toString())),
    gt: jest.fn((other: any) => parseFloat(value.toString()) > parseFloat(other.toString())),
    add: jest.fn((other: any) => createMockBN(parseFloat(value.toString()) + parseFloat(other.toString()))),
  };
}

jest.mock('@mystikonetwork/utils', () => ({
  DefaultProviderFactory: jest.fn().mockImplementation(() => ({
    createProvider: jest.fn(() => ({})),
  })),
  fromDecimals: jest.fn((value: any, decimals: number) => {
    // Convert the mock object to string and then to number
    const valueStr =
      typeof value === 'object' && value !== null && typeof value.toString === 'function'
        ? value.toString()
        : String(value);
    const numValue = parseFloat(valueStr);
    return numValue / 10 ** decimals;
  }),
  toBN: jest.fn((value: any) =>
    createMockBN(
      Number(
        typeof value === 'object' && value !== null && typeof value.toString === 'function'
          ? value.toString()
          : value,
      ),
    ),
  ),
  toDecimals: jest.fn((value: number, decimals: number) => ({
    gt: jest.fn(() => false),
    gte: jest.fn(() => true),
    lt: jest.fn(() => false),
    toString: () => (value * 10 ** decimals).toString(),
  })),
  BN: jest.fn((value: any) => createMockBN(Number(value))),
}));

// Mock BigNumber from ethers
jest.mock('ethers', () => ({
  BigNumber: {
    from: jest.fn((value: any) => ({
      toString: () => value.toString(),
    })),
  },
  PopulatedTransaction: jest.fn(),
}));

// Mock bn.js
jest.mock('bn.js', () => {
  return jest.fn((value: any) => createMockBN(Number(value)));
});

let stakingApiClient: typeof import('../../../src/api').default;

describe('StakingApiClient', () => {
  // Use the actual options from GlobalClientOptions
  const testOptions: ClientOptions = GlobalClientOptions[0]; // { tokenName: 'XZK', stakingPeriod: '365d' }
  const vxzkOptions: ClientOptions = GlobalClientOptions[3]; // { tokenName: 'vXZK', stakingPeriod: '180d' }
  const testInitOptions: InitOptions = { network: 'ethereum' };

  beforeEach(() => {
    jest.resetModules();
    stakingApiClient = require('../../../src/api').default;
    stakingApiClient.resetInitStatus();
    jest.clearAllMocks();
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

  it('should handle basic methods without error', async () => {
    stakingApiClient.initialize(testInitOptions);

    expect(stakingApiClient.isInitialized).toBe(true);
    expect(await stakingApiClient.getChainId(testOptions)).toBe(1);
    expect(await stakingApiClient.tokenContractAddress(testOptions)).toBeDefined();
    expect(await stakingApiClient.stakingContractAddress(testOptions)).toBeDefined();
    expect(await stakingApiClient.stakingStartTimestamp(testOptions)).toBe(1754438400);
    expect(await stakingApiClient.totalDurationSeconds(testOptions)).toBeDefined();
    expect(await stakingApiClient.stakingPeriodSeconds(testOptions)).toBeDefined();
    expect(await stakingApiClient.claimDelaySeconds(testOptions)).toBeDefined();
    expect(await stakingApiClient.isStakingPaused(testOptions)).toBe(true);
    expect(await stakingApiClient.totalStaked(testOptions)).toBeDefined();
    expect(await stakingApiClient.cumulativeTotalStaked(testOptions)).toBeDefined();
    expect(await stakingApiClient.cumulativeTotalUnstaked(testOptions)).toBeDefined();
    expect(await stakingApiClient.cumulativeTotalClaimed(testOptions)).toBeDefined();
    expect(await stakingApiClient.stakingTotalSupply(testOptions)).toBeDefined();
    expect(await stakingApiClient.totalRewardAt(testOptions)).toBeDefined();
    expect(await stakingApiClient.tokenBalance(testOptions, '0x')).toBeDefined();
    expect(await stakingApiClient.stakingBalance(testOptions, '0x')).toBeDefined();
    expect(await stakingApiClient.swapToStakingToken(testOptions, 1)).toBeDefined();
    expect(await stakingApiClient.swapToUnderlyingToken(testOptions, 1)).toBeDefined();
  });

  it('should return correct summary values for stakingSummary and unstakingSummary', async () => {
    stakingApiClient.initialize(testInitOptions);

    try {
      // stakingSummary
      const stakingSummary = await stakingApiClient.stakingSummary(testOptions, '0x');
      expect(stakingSummary).toHaveProperty('totalTokenAmount');
      expect(stakingSummary).toHaveProperty('totalStakingTokenAmount');
      expect(stakingSummary).toHaveProperty('totalStakingTokenRemaining');
      expect(stakingSummary).toHaveProperty('totalCanUnstakeAmount');
      expect(stakingSummary).toHaveProperty('records');
      expect(Array.isArray(stakingSummary.records)).toBe(true);
      expect(typeof stakingSummary.totalTokenAmount).toBe('number');
      expect(typeof stakingSummary.totalStakingTokenAmount).toBe('number');
      expect(typeof stakingSummary.totalStakingTokenRemaining).toBe('number');
      expect(typeof stakingSummary.totalCanUnstakeAmount).toBe('number');

      // unstakingSummary
      const unstakingSummary = await stakingApiClient.unstakingSummary(testOptions, '0x');
      expect(unstakingSummary).toHaveProperty('totalTokenAmount');
      expect(unstakingSummary).toHaveProperty('totalUnstakingTokenAmount');
      expect(unstakingSummary).toHaveProperty('totalCanClaimAmount');
      expect(unstakingSummary).toHaveProperty('records');
      expect(Array.isArray(unstakingSummary.records)).toBe(true);
      expect(typeof unstakingSummary.totalTokenAmount).toBe('number');
      expect(typeof unstakingSummary.totalUnstakingTokenAmount).toBe('number');
      expect(typeof unstakingSummary.totalCanClaimAmount).toBe('number');

      const claimSummary = await stakingApiClient.claimSummary(testOptions, '0x');
      expect(claimSummary).toHaveProperty('totalClaimedAmount');
      expect(claimSummary).toHaveProperty('records');
      expect(Array.isArray(claimSummary.records)).toBe(true);
      expect(typeof claimSummary.totalClaimedAmount).toBe('number');
    } catch (error: any) {
      console.error('Actual error:', error);
      console.error('Error message:', error.message);
      console.error('Error stack:', error.stack);
      throw error;
    }
  });

  it('should return correct stake action summary', async () => {
    stakingApiClient.initialize(testInitOptions);
    const stakeActionSummary = await stakingApiClient.stakeActionSummary(testOptions, 1000);
    expect(stakeActionSummary).toHaveProperty('tokenAmount');
    expect(stakeActionSummary).toHaveProperty('stakingTokenAmount');
    expect(stakeActionSummary).toHaveProperty('stakingTime');
    expect(stakeActionSummary).toHaveProperty('canUnstakeTime');
  });

  it('should return correct unstake action summary', async () => {
    stakingApiClient.initialize(testInitOptions);
    const unstakeActionSummary = await stakingApiClient.unstakeActionSummary(testOptions, 1000);
    expect(unstakeActionSummary).toHaveProperty('tokenAmount');
    expect(unstakeActionSummary).toHaveProperty('unstakingTokenAmount');
    expect(unstakeActionSummary).toHaveProperty('unstakingTime');
    expect(unstakeActionSummary).toHaveProperty('canClaimTime');
  });

  it('should work with different client options', async () => {
    stakingApiClient.initialize(testInitOptions);

    expect(await stakingApiClient.getChainId(vxzkOptions)).toBe(1);
    expect(await stakingApiClient.tokenContractAddress(vxzkOptions)).toBeDefined();
    expect(await stakingApiClient.stakingContractAddress(vxzkOptions)).toBeDefined();
  });

  it('should convert percentage APY correctly', async () => {
    // Test various percentage APY values
    const testCases = [
      { percentage: 15.23, wei: '152300000000000000', expected: 15.23 },
      { percentage: 8.5, wei: '85000000000000000', expected: 8.5 },
      { percentage: 25.0, wei: '250000000000000000', expected: 25.0 },
      { percentage: 3.141, wei: '31410000000000000', expected: 3.141 },
    ];

    for (const testCase of testCases) {
      // Reset the client before each test case
      stakingApiClient.resetInitStatus();

      // Mock the MystikoStakingContractFactory.connect to return a contract with the specific APY value
      const mockContract = {
        estimatedApr: jest.fn(() => Promise.resolve({ toString: () => testCase.wei })),
      };

      require('@expandzk/xzk-staking-abi').MystikoStakingContractFactory.connect = jest.fn(
        () => mockContract,
      );

      // Initialize the client after setting the mock
      stakingApiClient.initialize(testInitOptions);

      const apy = await stakingApiClient.estimatedApr(testOptions);
      expect(apy).toBe(testCase.expected);
      expect(typeof apy).toBe('number');
    }
  });

  it('should convert percentage APY staker correctly', async () => {
    // Test various percentage APY values
    const testCases = [
      { percentage: 15.23, wei: '152300000000000000', expected: 15.23 },
      { percentage: 8.5, wei: '85000000000000000', expected: 8.5 },
    ];

    for (const testCase of testCases) {
      // Reset the client before each test case
      stakingApiClient.resetInitStatus();

      const mockContract = {
        stakerApr: jest.fn(() => Promise.resolve({ toString: () => testCase.wei })),
      };

      require('@expandzk/xzk-staking-abi').MystikoStakingContractFactory.connect = jest.fn(
        () => mockContract,
      );

      // Initialize the client after setting the mock
      stakingApiClient.initialize(testInitOptions);

      const apy = await stakingApiClient.stakerApr(testOptions);
      expect(apy).toBe(testCase.expected);
      expect(typeof apy).toBe('number');
    }
  });

  it('should throw error for unsupported client options', async () => {
    stakingApiClient.initialize(testInitOptions);

    const unsupportedOptions: ClientOptions = { tokenName: 'XZK', stakingPeriod: '999d' as any };

    try {
      await stakingApiClient.getChainId(unsupportedOptions);
      // If we reach here, the test should fail
      expect(true).toBe(false);
    } catch (error: any) {
      expect(error.message).toContain('Not initialized');
    }
  });

  it('should return correct claim summary', async () => {
    stakingApiClient.initialize(testInitOptions);

    const claimSummary = await stakingApiClient.claimSummary(testOptions, '0x');
    expect(claimSummary).toHaveProperty('totalClaimedAmount');
    expect(claimSummary).toHaveProperty('records');
    expect(Array.isArray(claimSummary.records)).toBe(true);
    expect(typeof claimSummary.totalClaimedAmount).toBe('number');
  });
});
