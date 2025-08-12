import { describe, it, before, after } from 'mocha';
import { expect } from 'chai';
import stakingApiClient from '../../src/api';
import type { ClientOptions, InitOptions, TokenName, StakingPeriod } from '../../src/index';
import { ethers } from 'ethers';
import { config } from 'dotenv';

config();

// Test configuration
const testInitOptions: InitOptions = {
  network: 'ethereum',
  // stakingBackendUrl: 'http://0.0.0.0:3000/api',
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

  before(async () => {
    // Initialize API client
    stakingApiClient.initialize(testInitOptions);
  });

  after(() => {
    // Clean up resources
    stakingApiClient.resetInitStatus();
  });

  describe('check total reward', () => {
    it('should check total reward for XZK 365d', async () => {
      const startTime = await stakingApiClient.stakingStartTimestamp(clientXZK365d);
      expect(startTime).to.equal(1754438400);
      const durationSecond = await stakingApiClient.totalDurationSeconds(clientXZK365d);
      expect(durationSecond).to.equal(94608000);
      const endTime = startTime + durationSecond;
      expect(endTime).to.equal(1849046400);
      const xzk365PoolSummary = await stakingApiClient.stakingPoolSummary(clientXZK365d);
      const totalRewardXZK365d = await stakingApiClient.totalRewardAt(clientXZK365d, endTime);
      expect(totalRewardXZK365d).to.equal(11000000);
      expect(xzk365PoolSummary.totalReward).to.equal(totalRewardXZK365d);

      const xzk180PoolSummary = await stakingApiClient.stakingPoolSummary(clientXZK180d);
      const totalRewardXZK180d = await stakingApiClient.totalRewardAt(clientXZK180d, endTime);
      expect(totalRewardXZK180d).to.equal(5400000);
      expect(xzk180PoolSummary.totalReward).to.equal(totalRewardXZK180d);

      const xzk90PoolSummary = await stakingApiClient.stakingPoolSummary(clientXZK90d);
      const totalRewardXZK90d = await stakingApiClient.totalRewardAt(clientXZK90d, endTime);
      expect(totalRewardXZK90d).to.equal(2600000);
      expect(xzk90PoolSummary.totalReward).to.equal(totalRewardXZK90d);

      const xzkFlexPoolSummary = await stakingApiClient.stakingPoolSummary(clientXZKFlex);
      const totalRewardXZKFlex = await stakingApiClient.totalRewardAt(clientXZKFlex, endTime);
      expect(totalRewardXZKFlex).to.equal(1000000);
      expect(xzkFlexPoolSummary.totalReward).to.equal(totalRewardXZKFlex);

      const vXZK365PoolSummary = await stakingApiClient.stakingPoolSummary(clientvXZK365d);
      const totalRewardvXZK365d = await stakingApiClient.totalRewardAt(clientvXZK365d, endTime);
      expect(totalRewardvXZK365d).to.equal(16500000);
      expect(vXZK365PoolSummary.totalReward).to.equal(totalRewardvXZK365d);

      const vXZK180PoolSummary = await stakingApiClient.stakingPoolSummary(clientvXZK180d);
      const totalRewardvXZK180d = await stakingApiClient.totalRewardAt(clientvXZK180d, endTime);
      expect(totalRewardvXZK180d).to.equal(8100000);
      expect(vXZK180PoolSummary.totalReward).to.equal(totalRewardvXZK180d);

      const vXZK90PoolSummary = await stakingApiClient.stakingPoolSummary(clientvXZK90d);
      const totalRewardvXZK90d = await stakingApiClient.totalRewardAt(clientvXZK90d, endTime);
      expect(totalRewardvXZK90d).to.equal(3900000);
      expect(vXZK90PoolSummary.totalReward).to.equal(totalRewardvXZK90d);

      const vXZKFlexPoolSummary = await stakingApiClient.stakingPoolSummary(clientvXZKFlex);
      const totalRewardvXZKFlex = await stakingApiClient.totalRewardAt(clientvXZKFlex, endTime);
      expect(totalRewardvXZKFlex).to.equal(1500000);
      expect(vXZKFlexPoolSummary.totalReward).to.equal(totalRewardvXZKFlex);
    });
  });

  it('health', async () => {
    stakingApiClient.initialize(testInitOptions);
    const health = await stakingApiClient.health();
    expect(health).to.equal('healthy');
  });

  it('summary', async () => {
    stakingApiClient.initialize(testInitOptions);
    const summary = await stakingApiClient.summary();
    console.log(summary);

    const poolSummary = await stakingApiClient.stakingPoolSummary(clientXZK365d);
    const poolSummary2 = await stakingApiClient.stakingPoolSummary(clientXZK180d);
    const poolSummary3 = await stakingApiClient.stakingPoolSummary(clientXZK90d);
    const poolSummary4 = await stakingApiClient.stakingPoolSummary(clientXZKFlex);
    const poolSummary5 = await stakingApiClient.stakingPoolSummary(clientvXZK365d);
    const poolSummary6 = await stakingApiClient.stakingPoolSummary(clientvXZK180d);
    const poolSummary7 = await stakingApiClient.stakingPoolSummary(clientvXZK90d);
    const poolSummary8 = await stakingApiClient.stakingPoolSummary(clientvXZKFlex);
    console.log(poolSummary);
    console.log(poolSummary2);
    console.log(poolSummary3);
    console.log(poolSummary4);
    console.log(poolSummary5);
    console.log(poolSummary6);
    console.log(poolSummary7);
    console.log(poolSummary8);
  });
});
