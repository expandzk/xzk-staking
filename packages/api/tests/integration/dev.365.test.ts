import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
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
  stakingPeriod: '365d',
};

let wallet: ethers.Wallet;
describe('Sepolia Dev Integration Tests - 365d Day Staking', () => {
  beforeAll(async () => {
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

  afterAll(() => {
    // Clean up resources
    stakingApiClient.resetInitStatus();
  });

  describe('Network Connection Tests', () => {
    it('should connect to Sepolia network successfully', async () => {
      const chainId = await stakingApiClient.getChainId(testOptions);
      expect(chainId).toBe(SEPOLIA_CHAIN_ID);
    });

    it('should get contract addresses on Sepolia', async () => {
      const tokenAddress = await stakingApiClient.tokenContractAddress(testOptions);
      const stakingAddress = await stakingApiClient.stakingContractAddress(testOptions);
      expect(tokenAddress).toBeDefined();
      expect(stakingAddress).toBeDefined();
      expect(tokenAddress).toMatch(/^0x[a-fA-F0-9]{40}$/);
      expect(stakingAddress).toMatch(/^0x[a-fA-F0-9]{40}$/);
    });
  });

  describe('Contract State Tests', () => {
    it('should get staking start timestamp', async () => {
      const startTime = await stakingApiClient.stakingStartTimestamp(testOptions);
      expect(startTime).toBeGreaterThan(0);
    });

    it('should get staking period configuration', async () => {
      const totalDuration = await stakingApiClient.totalDurationSeconds(testOptions);
      const stakingPeriod = await stakingApiClient.stakingPeriodSeconds(testOptions);
      const claimDelay = await stakingApiClient.claimDelaySeconds(testOptions);

      expect(totalDuration).toBe(14 * 24 * 60 * 60);
      expect(stakingPeriod).toBe(3 * 24 * 60 * 60);
      expect(claimDelay).toBe(10 * 60);
    });

    it('should get staking pause status', async () => {
      const isPaused = await stakingApiClient.isStakingPaused(testOptions);
      expect(typeof isPaused).toBe('boolean');
      expect(isPaused).toBe(false);
    });
  });

  describe('Token Balance Tests', () => {
    it('should get token balance for test account', async () => {
      const balance = await stakingApiClient.tokenBalance(testOptions, TEST_ACCOUNT);
      expect(balance).toBeGreaterThanOrEqual(0);
    });

    it('should get staking balance for test account', async () => {
      const stakingBalance = await stakingApiClient.stakingBalance(testOptions, TEST_ACCOUNT);
      expect(stakingBalance).toBeGreaterThanOrEqual(0);
    });
  });

  describe('Staking Summary Tests', () => {
    it('should get staking summary for test account', async () => {
      const summary = await stakingApiClient.stakingSummary(testOptions, TEST_ACCOUNT);
      console.log(summary);
      expect(summary).toHaveProperty('totalTokenAmount');
      expect(summary).toHaveProperty('totalStakingTokenAmount');
      expect(summary).toHaveProperty('totalStakingTokenRemaining');
      expect(summary).toHaveProperty('totalCanUnstakeAmount');
      expect(Array.isArray(summary.records)).toBe(true);
    });

    it('should get unstaking summary for test account', async () => {
      const unstakingSummary = await stakingApiClient.unstakingSummary(testOptions, TEST_ACCOUNT);
      console.log(unstakingSummary);
      expect(unstakingSummary).toHaveProperty('totalTokenAmount');
      expect(unstakingSummary).toHaveProperty('totalUnstakingTokenAmount');
      expect(unstakingSummary).toHaveProperty('totalTokenRemaining');
      expect(unstakingSummary).toHaveProperty('totalCanClaimAmount');
      expect(Array.isArray(unstakingSummary.records)).toBe(true);
    });

    it('should get claim summary for test account', async () => {
      const claimSummary = await stakingApiClient.claimSummary(testOptions, TEST_ACCOUNT);
      console.log(claimSummary);
      expect(claimSummary).toHaveProperty('totalClaimedAmount');
      expect(Array.isArray(claimSummary.records)).toBe(true);
    });
  });

  describe('Test approve transaction', () => {
    it('should handle insufficient balance for approve transaction', async () => {
      const balance = await stakingApiClient.tokenBalance(testOptions, TEST_ACCOUNT);
      expect(balance).toBeDefined();

      try {
        await stakingApiClient.tokenApprove(testOptions, TEST_ACCOUNT, false, balance + 1);
        expect(true).toBe(false);
      } catch (error: any) {
        expect(error.message).toContain('Insufficient balance error');
      }

      const tx = await stakingApiClient.tokenApprove(testOptions, TEST_ACCOUNT, false, balance / 10);
      if (tx) {
        const receipt = await wallet.sendTransaction(tx);
        const receipt2 = await receipt.wait(2);
        expect(receipt2.status).toBe(1);
      }
    });

    it('should handle approve transaction with max amount', async () => {
      const tx = await stakingApiClient.tokenApprove(testOptions, TEST_ACCOUNT, true);
      expect(tx).toBeDefined();
    });

    // it('test stake transaction', async () => {
    //   const balance = await stakingApiClient.tokenBalance(testOptions, TEST_ACCOUNT);
    //   expect(balance).toBeDefined();

    //   try {
    //     await stakingApiClient.stake(testOptions, TEST_ACCOUNT, false, balance + 1);
    //     expect(true).toBe(false);
    //   } catch (error: any) {
    //     expect(error.message).toContain('Insufficient balance error');
    //   }

    //   const tx = await stakingApiClient.stake(testOptions, TEST_ACCOUNT, false, balance / 10);
    //   expect(tx).toBeDefined();
    //   const receipt = await wallet.sendTransaction(tx);
    //   console.log(receipt.hash);
    //   const receipt2 = await receipt.wait(2);
    //   expect(receipt2.status).toBe(1);
    // });

    it('should handle approve amount error', async () => {
      try {
        await stakingApiClient.stake(testOptions, TEST_ACCOUNT, true);
        expect(true).toBe(false);
      } catch (error: any) {
        expect(error.message).toContain('Approve amount error');
      }
    });

    it('should handle insufficient balance for unstake transaction', async () => {
      const unstakeAmount = 1000000 * 10 ** 18;

      try {
        await stakingApiClient.unstake(testOptions, TEST_ACCOUNT, false, unstakeAmount);
        expect(true).toBe(false);
      } catch (error: any) {
        expect(error.message).toContain('Insufficient balance error');
      }

      try {
        await stakingApiClient.unstake(testOptions, TEST_ACCOUNT, true, 0);
        expect(true).toBe(false);
      } catch (error: any) {
        expect(error.message).toContain('Insufficient balance error');
      }
    });

    it('should build claim transaction successfully', async () => {
      try {
        const claimTx = await stakingApiClient.claim(testOptions, TEST_ACCOUNT);
        expect(claimTx).toHaveProperty('to');
        expect(claimTx).toHaveProperty('data');
      } catch (error: any) {
        // If there's no claimable amount, that's also a valid scenario
        expect(error.message).toContain('No claimable amount');
      }
    });

    describe('Token Conversion Tests', () => {
      it('should calculate swap to staking token', async () => {
        const amount = 1;
        const stakingAmount = await stakingApiClient.swapToStakingToken(testOptions, amount);
        expect(stakingAmount).toBeGreaterThan(0);
      });

      it('should calculate swap to underlying token', async () => {
        const amount = 0.1;
        const underlyingAmount = await stakingApiClient.swapToUnderlyingToken(testOptions, amount);
        expect(underlyingAmount).toBeGreaterThan(0);
      });
    });

    describe('APY Tests', () => {
      it('should calculate staker APY', async () => {
        const apy = await stakingApiClient.stakerApy(testOptions);
        console.log(apy);
        expect(apy).toBeGreaterThanOrEqual(0);
      });

      it('should calculate estimated APY', async () => {
        const apy = await stakingApiClient.estimatedApy(testOptions);
        console.log(apy);
        expect(apy).toBeGreaterThanOrEqual(0);
      });

      it('should calculate estimated APY with amount', async () => {
        const apy = await stakingApiClient.estimatedApy(testOptions, 1000);
        console.log(apy);
        expect(apy).toBeGreaterThanOrEqual(0);
      });
    });

    describe('Error Handling Tests', () => {
      it('should handle invalid account address', async () => {
        const invalidAddress = '0xinvalid';

        try {
          await stakingApiClient.tokenBalance(testOptions, invalidAddress);
          // If we reach here, the test should fail
          expect(true).toBe(false);
        } catch (error) {
          expect(error).toBeDefined();
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
          expect(true).toBe(false);
        } catch (error: any) {
          expect(error.message).toContain('Not initialized');
        }
      });
    });
  });
});
