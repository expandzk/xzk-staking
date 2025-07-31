import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import stakingApiClient from '../../src/api';
import type { ClientOptions, InitOptions, TokenName, StakingPeriod } from '../../src/index';
import { ethers } from 'ethers';
import { config } from 'dotenv';

config();

// Test configuration
const testInitOptions: InitOptions = {
  network: 'ethereum',
};

let wallet: ethers.Wallet;
describe('Mainnet Integration Tests - 365d Day Staking', () => {
  const clientXZK365d: ClientOptions = {
    tokenName: 'XZK' as TokenName,
    stakingPeriod: '365d' as StakingPeriod,
  };
  const clientXZK180d: ClientOptions = {
    tokenName: 'XZK' as TokenName,
    stakingPeriod: '180d' as StakingPeriod,
  };
  const clientXZK90d: ClientOptions = {
    tokenName: 'XZK' as TokenName,
    stakingPeriod: '90d' as StakingPeriod,
  };
  const clientXZKFlex: ClientOptions = {
    tokenName: 'XZK' as TokenName,
    stakingPeriod: 'Flex' as StakingPeriod,
  };
  const clientvXZK365d: ClientOptions = {
    tokenName: 'vXZK' as TokenName,
    stakingPeriod: '365d' as StakingPeriod,
  };
  const clientvXZK180d: ClientOptions = {
    tokenName: 'vXZK' as TokenName,
    stakingPeriod: '180d' as StakingPeriod,
  };
  const clientvXZK90d: ClientOptions = {
    tokenName: 'vXZK' as TokenName,
    stakingPeriod: '90d' as StakingPeriod,
  };
  const clientvXZKFlex: ClientOptions = {
    tokenName: 'vXZK' as TokenName,
    stakingPeriod: 'Flex' as StakingPeriod,
  };

  beforeAll(async () => {
    // Initialize API client
    stakingApiClient.initialize(testInitOptions);
  });

  afterAll(() => {
    // Clean up resources
    stakingApiClient.resetInitStatus();
  });

  describe('check total reward', () => {
    it('should check total reward for XZK 365d', async () => {
      const startTime = await stakingApiClient.stakingStartTimestamp(clientXZK365d);
      expect(startTime).toBe(1754438400);
      const durationSecond = await stakingApiClient.totalDurationSeconds(clientXZK365d);
      expect(durationSecond).toBe(94608000);
      const endTime = startTime + durationSecond;
      expect(endTime).toBe(1849046400);
      const xzk365PoolSummary = await stakingApiClient.stakingPoolSummary(clientXZK365d);
      const totalRewardXZK365d = await stakingApiClient.totalRewardAt(clientXZK365d, endTime);
      expect(totalRewardXZK365d).toBe(11000000);
      expect(xzk365PoolSummary.totalReward).toBe(totalRewardXZK365d);

      const xzk180PoolSummary = await stakingApiClient.stakingPoolSummary(clientXZK180d);
      const totalRewardXZK180d = await stakingApiClient.totalRewardAt(clientXZK180d, endTime);
      expect(totalRewardXZK180d).toBe(5400000);
      expect(xzk180PoolSummary.totalReward).toBe(totalRewardXZK180d);

      const xzk90PoolSummary = await stakingApiClient.stakingPoolSummary(clientXZK90d);
      const totalRewardXZK90d = await stakingApiClient.totalRewardAt(clientXZK90d, endTime);
      expect(totalRewardXZK90d).toBe(2600000);
      expect(xzk90PoolSummary.totalReward).toBe(totalRewardXZK90d);

      const xzkFlexPoolSummary = await stakingApiClient.stakingPoolSummary(clientXZKFlex);
      const totalRewardXZKFlex = await stakingApiClient.totalRewardAt(clientXZKFlex, endTime);
      expect(totalRewardXZKFlex).toBe(1000000);
      expect(xzkFlexPoolSummary.totalReward).toBe(totalRewardXZKFlex);

      const vXZK365PoolSummary = await stakingApiClient.stakingPoolSummary(clientvXZK365d);
      const totalRewardvXZK365d = await stakingApiClient.totalRewardAt(clientvXZK365d, endTime);
      expect(totalRewardvXZK365d).toBe(16500000);
      expect(vXZK365PoolSummary.totalReward).toBe(totalRewardvXZK365d);

      const vXZK180PoolSummary = await stakingApiClient.stakingPoolSummary(clientvXZK180d);
      const totalRewardvXZK180d = await stakingApiClient.totalRewardAt(clientvXZK180d, endTime);
      expect(totalRewardvXZK180d).toBe(8100000);
      expect(vXZK180PoolSummary.totalReward).toBe(totalRewardvXZK180d);

      const vXZK90PoolSummary = await stakingApiClient.stakingPoolSummary(clientvXZK90d);
      const totalRewardvXZK90d = await stakingApiClient.totalRewardAt(clientvXZK90d, endTime);
      expect(totalRewardvXZK90d).toBe(3900000);
      expect(vXZK90PoolSummary.totalReward).toBe(totalRewardvXZK90d);

      const vXZKFlexPoolSummary = await stakingApiClient.stakingPoolSummary(clientvXZKFlex);
      const totalRewardvXZKFlex = await stakingApiClient.totalRewardAt(clientvXZKFlex, endTime);
      expect(totalRewardvXZKFlex).toBe(1500000);
      expect(vXZKFlexPoolSummary.totalReward).toBe(totalRewardvXZKFlex);
    });

    it('should check init staking pool summary', async () => {
      for (const client of [
        clientXZK365d,
        clientXZK180d,
        clientXZK90d,
        clientXZKFlex,
        clientvXZK365d,
        clientvXZK180d,
        clientvXZK90d,
        clientvXZKFlex,
      ]) {
        const isClaimToDaoEnabled = await stakingApiClient.isClaimToDaoEnabled(client);
        expect(isClaimToDaoEnabled).toBe(false);
      }
    });
  });
});
