import type { } from 'jest';
import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { Client } from '../src/client';
import { InitOptions } from '../src/index';
import { XZKStakingErrorCode } from '../src/error';

// Mock the Config module
jest.mock('../src/config', () => ({
  Config: jest.fn(),
}));

describe('Client', () => {
  let client: Client;
  let mockProvider: any;
  let mockConfig: any;
  let mockTokenInstance: any;
  let mockStakingInstance: any;
  let MockConfig: any;

  beforeEach(() => {
    client = new Client();
    mockProvider = {};
    mockConfig = {
      chainId: 1,
      decimals: 18,
      providers: ['https://eth-mainnet.public.blastapi.io'],
      tokenContractInstance: jest.fn(() => mockTokenInstance),
      stakingContractInstance: jest.fn(() => mockStakingInstance),
      tokenContractAddress: jest.fn(() => '0xToken'),
      stakingContractAddress: jest.fn(() => '0xStaking'),
      totalDurationSeconds: jest.fn(() => 100),
      claimDelaySeconds: jest.fn(() => 10),
      stakingPeriodSeconds: jest.fn(() => 20),
    };
    mockTokenInstance = {
      balanceOf: jest.fn(() => Promise.resolve({ toString: () => '1000000000000000000000000000000000000000' })),
      allowance: jest.fn(() => Promise.resolve({ toString: () => '100000000000000000000' })),
      populateTransaction: {
        approve: jest.fn(() => Promise.resolve({ tx: 'approve' })),
      },
    };
    mockStakingInstance = {
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
        amount: { toString: () => '2000000000000000000' }, // 2 * 10^18
        remaining: { toString: () => '3000000000000000000' } // 3 * 10^18
      })),
      claimRecords: jest.fn(() => Promise.resolve({
        unstakeTime: { toNumber: () => 1 },
        amount: { toString: () => '2000000000000000000' }, // 2 * 10^18
        claimPaused: false
      })),
      populateTransaction: {
        stake: jest.fn(() => Promise.resolve({ tx: 'stake' })),
        unstake: jest.fn(() => Promise.resolve({ tx: 'unstake' })),
        claim: jest.fn(() => Promise.resolve({ tx: 'claim' })),
      },
    };

    // Get the mocked Config constructor
    const { Config } = require('../src/config');
    MockConfig = Config;
    MockConfig.mockImplementation(() => mockConfig);
  });

  it('should not be initialized by default', () => {
    expect(client.isInitialized).toBe(false);
  });

  it('should initialize and set isInitialized', () => {
    const options: InitOptions = { stakingContractName: 'sXZK365d' };
    client.initialize(options);
    expect(client.isInitialized).toBe(true);
    expect(MockConfig).toHaveBeenCalledWith(1);
  });

  it('should reset initialization status', () => {
    client.resetInitStatus();
    expect(client.isInitialized).toBe(false);
  });

  it('should return error if not initialized for methods', async () => {
    await expect(client.getChainId()).rejects.toThrow(/Client not initialized/);
    await expect(client.tokenContractAddress()).rejects.toThrow(/Client not initialized/);
    await expect(client.stakingContractAddress()).rejects.toThrow(/Client not initialized/);
    await expect(client.stakingStartTimestamp()).rejects.toThrow(/Client not initialized/);
    await expect(client.totalDurationSeconds()).rejects.toThrow(/Client not initialized/);
    await expect(client.stakingPeriodSeconds()).rejects.toThrow(/Client not initialized/);
    await expect(client.claimDelaySeconds()).rejects.toThrow(/Client not initialized/);
    await expect(client.isStakingPaused()).rejects.toThrow(/Client not initialized/);
    await expect(client.totalStaked()).rejects.toThrow(/Client not initialized/);
    await expect(client.totalUnstaked()).rejects.toThrow(/Client not initialized/);
    await expect(client.currentTotalReward()).rejects.toThrow(/Client not initialized/);
    await expect(client.tokenBalance('0x')).rejects.toThrow(/Client not initialized/);
    await expect(client.stakingTotalSupply()).rejects.toThrow(/Client not initialized/);
    await expect(client.stakingBalance('0x')).rejects.toThrow(/Client not initialized/);
    await expect(client.swapToStakingToken(1)).rejects.toThrow(/Client not initialized/);
    await expect(client.swapToUnderlyingToken(1)).rejects.toThrow(/Client not initialized/);
    await expect(client.stakingSummary('0x')).rejects.toThrow(/Client not initialized/);
    await expect(client.claimSummary('0x')).rejects.toThrow(/Client not initialized/);
    await expect(client.tokenApprove('0x', 1)).rejects.toThrow(/Client not initialized/);
    await expect(client.stake('0x', 1)).rejects.toThrow(/Client not initialized/);
    await expect(client.unstake('0x', 1, [1])).rejects.toThrow(/Client not initialized/);
    await expect(client.claim()).rejects.toThrow(/Client not initialized/);
  });

  it('should return correct values for initialized client', async () => {
    const options: InitOptions = { stakingContractName: 'sXZK365d' };
    client.initialize(options);

    expect(client.isInitialized).toBe(true);
    expect(await client.getChainId()).toBe(1);
    expect(await client.tokenContractAddress()).toBe('0xToken');
    expect(await client.stakingContractAddress()).toBe('0xStaking');
    expect(await client.stakingStartTimestamp()).toBe(123);
    expect(await client.totalDurationSeconds()).toBe(100);
    expect(await client.stakingPeriodSeconds()).toBe(20);
    expect(await client.claimDelaySeconds()).toBe(10);
    expect(await client.isStakingPaused()).toBe(0);
    expect(await client.totalStaked()).toBe(100);
    expect(await client.totalUnstaked()).toBe(10);
    expect(await client.stakingTotalSupply()).toBe(100);
    expect(await client.currentTotalReward()).toBe(5);
    expect(await client.tokenBalance('0x')).toBe(1000);
    expect(await client.stakingBalance('0x')).toBe(50);
    expect(await client.swapToStakingToken(1)).toBe(10);
    expect(await client.swapToUnderlyingToken(1)).toBe(10);

    // Test stakingSummary returns the expected structure
    const stakingSummary = await client.stakingSummary('0x');
    expect(stakingSummary).toEqual({
      nonce: 2,
      totalStaked: 4, // 2 records * 2 each = 4
      totalCanUnstake: 6, // 2 records * 3 each = 6
      records: [{
        stakedTime: 1,
        amount: 2,
        remaining: 3
      }, {
        stakedTime: 1,
        amount: 2,
        remaining: 3
      }]
    });

    // Test claimSummary returns the expected structure
    const claimSummary = await client.claimSummary('0x');
    expect(claimSummary).toEqual({
      unstakeTime: 1,
      amount: 2,
      claimable: true,
      paused: false
    });

    // Test transaction methods return PopulatedTransaction objects
    const approveTx = await client.tokenApprove('0x', 1);
    expect(approveTx).toEqual({ tx: 'approve' });

    const stakeTx = await client.stake('0x', 1);
    expect(stakeTx).toEqual({ tx: 'stake' });

    const unstakeTx = await client.unstake('0x', 1, [1]);
    expect(unstakeTx).toEqual({ tx: 'unstake' });

    const claimTx = await client.claim();
    expect(claimTx).toEqual({ tx: 'claim' });
  });
});
