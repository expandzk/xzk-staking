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
const TEST_ACCOUNT = '0x9c5e5b9f051b772f43f2f8a32cf852dd243d5c8a';
const TEST_PRIVATE_KEY = process.env.TEST_PRIVATE_KEY;

// Test configuration
const testInitOptions: InitOptions = {
  network: 'dev',
  scanApiBaseUrl: 'https://api-sepolia.etherscan.io/api',
};

// 365-day staking options
const testOptions: ClientOptions = {
  tokenName: 'XZK',
  stakingPeriod: 'Flex',
};

let wallet: ethers.Wallet;
describe('Sepolia Dev Integration Tests - 365d Day Staking', () => {
  before(async () => {
    // Initialize API client
    stakingApiClient.initialize(testInitOptions);

    if (!TEST_PRIVATE_KEY) {
      throw new Error('TEST_PRIVATE_KEY environment variable is required');
    }
    wallet = new ethers.Wallet(
      TEST_PRIVATE_KEY,
      new ethers.providers.JsonRpcProvider('https://1rpc.io/sepolia'),
    );

    // Wait for initialization to complete
    await new Promise((resolve) => {
      setTimeout(resolve, 2000);
    });
  });

  after(() => {
    // Clean up resources
    stakingApiClient.resetInitStatus();
  });

  describe('Network Connection Tests', () => {
    it('should connect to Sepolia network successfully', async () => {
      const chainId = await stakingApiClient.getChainId(testOptions);
      expect(chainId).to.equal(SEPOLIA_CHAIN_ID);
    });

    it('should get contract addresses on Sepolia', async () => {
      const tokenAddress = await stakingApiClient.tokenContractAddress(testOptions);
      const stakingAddress = await stakingApiClient.stakingContractAddress(testOptions);
      expect(tokenAddress).to.not.be.undefined;
      expect(stakingAddress).to.not.be.undefined;
      expect(tokenAddress).to.match(/^0x[a-fA-F0-9]{40}$/);
      expect(stakingAddress).to.match(/^0x[a-fA-F0-9]{40}$/);
    });
  });

  describe('Contract State Tests', () => {
    it('should get staking start timestamp', async () => {
      const startTime = await stakingApiClient.stakingStartTimestamp(testOptions);
      expect(startTime).to.be.greaterThan(0);
    });

    it('should get staking period configuration', async () => {
      const totalDuration = await stakingApiClient.totalDurationSeconds(testOptions);
      const stakingPeriod = await stakingApiClient.stakingPeriodSeconds(testOptions);
      const claimDelay = await stakingApiClient.claimDelaySeconds(testOptions);

      expect(totalDuration).to.equal(14 * 24 * 60 * 60);
      expect(stakingPeriod).to.equal(4 * 60 * 60); // 4 hours = 14400 seconds
      expect(claimDelay).to.equal(10 * 60);
    });

    it('should get staking pause status', async () => {
      const isPaused = await stakingApiClient.isStakingPaused(testOptions);
      expect(typeof isPaused).to.equal('boolean');
      expect(isPaused).to.be.false;
    });
  });

  describe('Token Balance Tests', () => {
    it('should get token balance for test account', async () => {
      const balance = await stakingApiClient.tokenBalance(testOptions, TEST_ACCOUNT);
      expect(balance).to.be.at.least(0);
    });

    it('should get staking balance for test account', async () => {
      const stakingBalance = await stakingApiClient.stakingBalance(testOptions, TEST_ACCOUNT);
      expect(stakingBalance).to.be.at.least(0);
    });
  });

  describe('Staking Summary Tests', () => {
    it('should get staking summary for test account', async () => {
      const summary = await stakingApiClient.stakingSummary(testOptions, TEST_ACCOUNT);
      console.log(summary);
      expect(summary).to.have.property('totalTokenAmount');
      expect(summary).to.have.property('totalStakingTokenAmount');
      expect(summary).to.have.property('totalStakingTokenRemaining');
      expect(summary).to.have.property('totalCanUnstakeAmount');
      expect(summary.records).to.be.an('array');
    });

    it('should get unstaking summary for test account', async () => {
      const unstakingSummary = await stakingApiClient.unstakingSummary(testOptions, TEST_ACCOUNT);
      console.log(unstakingSummary);
      expect(unstakingSummary).to.have.property('totalTokenAmount');
      expect(unstakingSummary).to.have.property('totalUnstakingTokenAmount');
      expect(unstakingSummary).to.have.property('totalTokenRemaining');
      expect(unstakingSummary).to.have.property('totalCanClaimAmount');
      expect(unstakingSummary.records).to.be.an('array');
    });

    it('should get claim summary for test account', async () => {
      const claimSummary = await stakingApiClient.claimSummary(testOptions, TEST_ACCOUNT);
      console.log(claimSummary);
      expect(claimSummary).to.have.property('totalClaimedAmount');
      expect(claimSummary.records).to.be.an('array');
    });
  });

  describe('Test approve transaction', () => {
    it('should handle insufficient balance for approve transaction', async () => {
      const balance = await stakingApiClient.tokenBalance(testOptions, TEST_ACCOUNT);
      expect(balance).to.not.be.undefined;

      try {
        await stakingApiClient.tokenApprove(testOptions, TEST_ACCOUNT, false, balance + 1);
        expect(true).to.be.false;
      } catch (error: any) {
        expect(error.message).to.contain('Insufficient balance error');
      }

      const tx = await stakingApiClient.tokenApprove(testOptions, TEST_ACCOUNT, false, balance / 10);
      if (tx) {
        const receipt = await wallet.sendTransaction(tx);
        const receipt2 = await receipt.wait(2);
        expect(receipt2.status).to.equal(1);
      }
    });

    it('should handle approve transaction with max amount', async () => {
      const tx = await stakingApiClient.tokenApprove(testOptions, TEST_ACCOUNT, true);
      expect(tx).to.not.be.undefined;
    });

    it('test stake transaction', async () => {
      const balance = await stakingApiClient.tokenBalance(testOptions, TEST_ACCOUNT);
      expect(balance).to.not.be.undefined;

      try {
        await stakingApiClient.stake(testOptions, TEST_ACCOUNT, false, balance + 1);
        expect(true).to.be.false;
      } catch (error: any) {
        expect(error.message).to.contain('Insufficient balance error');
      }

      const tx = await stakingApiClient.stake(testOptions, TEST_ACCOUNT, false, balance / 10);
      expect(tx).to.not.be.undefined;
      const receipt = await wallet.sendTransaction(tx);
      console.log(receipt.hash);
      const receipt2 = await receipt.wait(2);
      expect(receipt2.status).to.equal(1);
    });

    it('should handle approve amount error', async () => {
      try {
        await stakingApiClient.stake(testOptions, TEST_ACCOUNT, true);
        expect(true).to.be.false;
      } catch (error: any) {
        expect(error.message).to.contain('Approve amount error');
      }
    });

    it('should handle insufficient balance for unstake transaction', async () => {
      const unstakeAmount = 1000000 * 10 ** 18;

      try {
        await stakingApiClient.unstake(testOptions, TEST_ACCOUNT, false, unstakeAmount);
        expect(true).to.be.false;
      } catch (error: any) {
        expect(error.message).to.contain('Insufficient balance error');
      }

      try {
        await stakingApiClient.unstake(testOptions, TEST_ACCOUNT, true, 0);
        expect(true).to.be.false;
      } catch (error: any) {
        expect(error.message).to.contain('Insufficient balance error');
      }
    });

    it('should build claim transaction successfully', async () => {
      try {
        const claimTx = await stakingApiClient.claim(testOptions, TEST_ACCOUNT);
        expect(claimTx).to.have.property('to');
        expect(claimTx).to.have.property('data');
      } catch (error: any) {
        // If there's no claimable amount, that's also a valid scenario
        expect(error.message).to.contain('No claimable amount');
      }
    });

    describe('Token Conversion Tests', () => {
      it('should calculate swap to staking token', async () => {
        const amount = 1;
        const stakingAmount = await stakingApiClient.swapToStakingToken(testOptions, amount);
        expect(stakingAmount).to.be.greaterThan(0);
      });

      it('should calculate swap to underlying token', async () => {
        const amount = 0.1;
        const underlyingAmount = await stakingApiClient.swapToUnderlyingToken(testOptions, amount);
        expect(underlyingAmount).to.be.greaterThan(0);
      });
    });

    describe('APR Tests', () => {
      it('should calculate staker APR', async () => {
        const apr = await stakingApiClient.stakerApr(testOptions);
        console.log(apr);
        expect(apr).to.be.at.least(0);
      });

      it('should calculate estimated APR', async () => {
        const apr = await stakingApiClient.estimatedApr(testOptions);
        console.log(apr);
        expect(apr).to.be.at.least(0);
      });

      it('should calculate estimated APR with amount', async () => {
        const apr = await stakingApiClient.estimatedApr(testOptions, 1000);
        console.log(apr);
        expect(apr).to.be.at.least(0);
      });
    });

    describe('Error Handling Tests', () => {
      it('should handle invalid account address', async () => {
        const invalidAddress = '0xinvalid';

        try {
          await stakingApiClient.tokenBalance(testOptions, invalidAddress);
          // If we reach here, the test should fail
          expect(true).to.be.false;
        } catch (error) {
          expect(error).to.not.be.undefined;
        }
      });

      it('should handle unsupported client options', async () => {
        const unsupportedOptions: ClientOptions = {
          tokenName: 'XZK',
          stakingPeriod: '999d' as any,
        };

        try {
          await stakingApiClient.getChainId(unsupportedOptions);
          // If we reach here, the test should fail
          expect(true).to.be.false;
        } catch (error: any) {
          expect(error.message).to.contain('Not initialized');
        }
      });
    });
  });
});
