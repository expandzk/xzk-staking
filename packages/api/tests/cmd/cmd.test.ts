import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import stakingApiClient from '../../src/api';
import type { ClientOptions, InitOptions } from '../../src/index';
import { ethers } from 'ethers';
import { config } from 'dotenv';

config();

// Sepolia test configuration
const SEPOLIA_CHAIN_ID = 11155111;

// Test accounts (replace with actual test accounts)
const TEST_ACCOUNT = '';

// Test configuration
const testInitOptions: InitOptions = {
  network: 'ethereum',
  scanApiBaseUrl: 'https://api-sepolia.etherscan.io/api',
};

// 365-day staking options
const testOptions: ClientOptions = {
  tokenName: 'XZK',
  stakingPeriod: 'Flex',
};

let wallet: ethers.Wallet;
describe('Sepolia Dev Integration Tests - 365d Day Staking', () => {
  beforeAll(async () => {
    // Initialize API client
    stakingApiClient.initialize(testInitOptions);

    // Wait for initialization to complete
    await new Promise((resolve) => {
      setTimeout(resolve, 2000);
    });
  });

  afterAll(() => {
    // Clean up resources
    stakingApiClient.resetInitStatus();
  });

  describe('Get Summary', () => {
    it('should get staking summary for test account', async () => {
      const stakingPeriodSeconds = await stakingApiClient.stakingPeriodSeconds(testOptions);
      console.log(stakingPeriodSeconds);
      const contractAddress = await stakingApiClient.stakingContractAddress(testOptions);
      console.log(contractAddress);
      console.log(TEST_ACCOUNT);
      const summary = await stakingApiClient.stakingSummary(testOptions, TEST_ACCOUNT);
      console.log(summary);
      expect(summary).toHaveProperty('totalTokenAmount');
      expect(summary).toHaveProperty('totalStakingTokenAmount');
      expect(summary).toHaveProperty('totalStakingTokenRemaining');
      expect(summary).toHaveProperty('totalStakingTokenLocked');
      expect(summary).toHaveProperty('totalCanUnstakeAmount');
      expect(Array.isArray(summary.records)).toBe(true);
    });

    it('should get unstaking summary for test account', async () => {
      const unstakingSummary = await stakingApiClient.unstakingSummary(testOptions, TEST_ACCOUNT);
      console.log(unstakingSummary);
      expect(unstakingSummary).toHaveProperty('totalTokenAmount');
      expect(unstakingSummary).toHaveProperty('totalUnstakingTokenAmount');
      expect(unstakingSummary).toHaveProperty('totalTokenRemaining');
      expect(unstakingSummary).toHaveProperty('totalTokenLocked');
      expect(unstakingSummary).toHaveProperty('totalCanClaimAmount');
      expect(Array.isArray(unstakingSummary.records)).toBe(true);
    });

    it('should get claim summary for test account', async () => {
      const claimSummary = await stakingApiClient.claimSummary(testOptions, TEST_ACCOUNT);
      console.log(claimSummary);
      expect(claimSummary).toHaveProperty('totalClaimedAmount');
      expect(Array.isArray(claimSummary.records)).toBe(true);
    });

    it('should get staking pool config', async () => {
      const stakingPoolConfig = await stakingApiClient.getStakingPoolConfig(testOptions);
      console.log(stakingPoolConfig);
      expect(stakingPoolConfig).toHaveProperty('chainId');
      expect(stakingPoolConfig).toHaveProperty('tokenName');
      expect(stakingPoolConfig).toHaveProperty('tokenDecimals');
    });

    it('should total summary', async () => {
      const xzkAmountSummary = await stakingApiClient.totalXzkAmountSummary();
      console.log(xzkAmountSummary);
      const vxzkAmountSummary = await stakingApiClient.totalVxzkAmountSummary();
      console.log(vxzkAmountSummary);
      const totalRewardXzkAmount = await stakingApiClient.totalRewardXzkAmountSummary();
      console.log(totalRewardXzkAmount);
      const totalRewardVxzkAmount = await stakingApiClient.totalRewardVxzkAmountSummary();
      console.log(totalRewardVxzkAmount);
    });

    it('should get is stake disabled', async () => {
      const isStakeDisabled = await stakingApiClient.isStakeDisabled(testOptions);
      console.log(isStakeDisabled);
      expect(isStakeDisabled).toBe(false);
    });

    it('should get is staking paused', async () => {
      const isStakingPaused = await stakingApiClient.isStakingPaused(testOptions);
      console.log(isStakingPaused);
      expect(isStakingPaused).toBe(false);
    });

    it('should get is claim paused', async () => {
      const isClaimPaused = await stakingApiClient.isClaimPaused(testOptions, TEST_ACCOUNT);
      console.log(isClaimPaused);
      expect(isClaimPaused).toBe(false);
    });

    it('should get staking pool summary', async () => {
      const totalReward = await stakingApiClient.totalRewardXzkAmountSummary();
      console.log('totalReward', totalReward);
      const totalRewardVxzk = await stakingApiClient.totalRewardVxzkAmountSummary();
      console.log('totalRewardVxzk', totalRewardVxzk);

      const totalStaked = await stakingApiClient.cumulativeTotalStaked(testOptions);
      console.log('totalStaked', totalStaked);
      const totalUnstaked = await stakingApiClient.cumulativeTotalUnstaked(testOptions);
      console.log('totalUnstaked', totalUnstaked);
      const totalClaimed = await stakingApiClient.cumulativeTotalClaimed(testOptions);
      console.log('totalClaimed', totalClaimed);

      const apr = await stakingApiClient.estimatedApr(testOptions);
      console.log('estimatedApr', apr);
      const stakerApr = await stakingApiClient.stakerApr(testOptions);
      console.log('stakerApr', stakerApr);

      const stakingPoolSummary = await stakingApiClient.stakingPoolSummary(testOptions);
      console.log(stakingPoolSummary);
      expect(stakingPoolSummary).toHaveProperty('currentReward');
      expect(stakingPoolSummary).toHaveProperty('totalReward');
      expect(stakingPoolSummary).toHaveProperty('rewardRate');
    });
  });
});
