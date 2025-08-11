import { describe, it, before, after } from 'mocha';
import { expect } from 'chai';
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
};

// 365-day staking options
const testOptions: ClientOptions = {
  tokenName: 'XZK',
  stakingPeriod: '365d',
};

let wallet: ethers.Wallet;
describe('Ethereum Dev Integration Tests - 365d Day Staking', () => {
  before(async () => {
    // Initialize API client
    stakingApiClient.initialize(testInitOptions);

    // Wait for initialization to complete
    await new Promise((resolve) => {
      setTimeout(resolve, 2000);
    });
  });

  after(() => {
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
      expect(summary).to.have.property('totalTokenAmount');
      expect(summary).to.have.property('totalStakingTokenAmount');
      expect(summary).to.have.property('totalStakingTokenRemaining');
      expect(summary).to.have.property('totalStakingTokenLocked');
      expect(summary).to.have.property('totalCanUnstakeAmount');
      expect(summary.records).to.be.an('array');
    });

    it('should get unstaking summary for test account', async () => {
      const unstakingSummary = await stakingApiClient.unstakingSummary(testOptions, TEST_ACCOUNT);
      console.log(unstakingSummary);
      expect(unstakingSummary).to.have.property('totalTokenAmount');
      expect(unstakingSummary).to.have.property('totalUnstakingTokenAmount');
      expect(unstakingSummary).to.have.property('totalTokenRemaining');
      expect(unstakingSummary).to.have.property('totalTokenLocked');
      expect(unstakingSummary).to.have.property('totalCanClaimAmount');
      expect(unstakingSummary.records).to.be.an('array');
    });

    it('should get claim summary for test account', async () => {
      const claimSummary = await stakingApiClient.claimSummary(testOptions, TEST_ACCOUNT);
      console.log(claimSummary);
      expect(claimSummary).to.have.property('totalClaimedAmount');
      expect(claimSummary.records).to.be.an('array');
    });

    it('should get staking pool config', async () => {
      const stakingPoolConfig = await stakingApiClient.getStakingPoolConfig(testOptions);
      console.log(stakingPoolConfig);
      expect(stakingPoolConfig).to.have.property('chainId');
      expect(stakingPoolConfig).to.have.property('tokenName');
      expect(stakingPoolConfig).to.have.property('tokenDecimals');
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
      expect(isStakeDisabled).to.be.false;
    });

    it('should get is staking paused', async () => {
      const isStakingPaused = await stakingApiClient.isStakingPaused(testOptions);
      console.log(isStakingPaused);
      expect(isStakingPaused).to.be.false;
    });

    it('should get is claim paused', async () => {
      const isClaimPaused = await stakingApiClient.isClaimPaused(testOptions, TEST_ACCOUNT);
      console.log(isClaimPaused);
      expect(isClaimPaused).to.be.false;
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
      expect(stakingPoolSummary).to.have.property('currentReward');
      expect(stakingPoolSummary).to.have.property('totalReward');
      expect(stakingPoolSummary).to.have.property('rewardRate');
    });
  });
});
