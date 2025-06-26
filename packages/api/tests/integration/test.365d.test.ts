import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import stakingApiClient from '../../src/api';
import type { ClientOptions } from '../../src/index';

// Sepolia test configuration
const SEPOLIA_CHAIN_ID = 11155111;

// Test accounts (replace with actual test accounts)
const TEST_ACCOUNT = '0x1234567890123456789012345678901234567890'; // Replace with actual test account
// const TEST_PRIVATE_KEY = process.env.TEST_PRIVATE_KEY || '0x1234567890123456789012345678901234567890'; // Get from environment variable

// Test configuration
const testInitOptions = {
  chainId: SEPOLIA_CHAIN_ID,
  scanApiBaseUrl: 'https://api-sepolia.etherscan.io/api',
};

// 365-day staking options
const testOptions: ClientOptions = {
  tokenName: 'XZK',
  stakingPeriod: '365d',
};

describe('Sepolia Integration Tests - 365 Day Staking', () => {
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

      expect(totalDuration).toBeGreaterThan(0);
      expect(stakingPeriod).toBeGreaterThan(0);
      expect(claimDelay).toBeGreaterThan(0);

      // 365-day staking period should be 365 * 24 * 60 * 60 seconds
      expect(stakingPeriod).toBe(365 * 24 * 60 * 60);
    });

    it('should get staking pause status', async () => {
      const isPaused = await stakingApiClient.isStakingPaused(testOptions);
      expect(typeof isPaused).toBe('boolean');
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
      expect(summary).toHaveProperty('totalTokenAmount');
      expect(summary).toHaveProperty('totalStakingTokenAmount');
      expect(summary).toHaveProperty('totalStakingTokenRemaining');
      expect(summary).toHaveProperty('totalCanUnstakeAmount');
      expect(Array.isArray(summary.records)).toBe(true);
    });

    it('should get unstaking summary for test account', async () => {
      const unstakingSummary = await stakingApiClient.unstakingSummary(testOptions, TEST_ACCOUNT);
      expect(unstakingSummary).toHaveProperty('totalTokenAmount');
      expect(unstakingSummary).toHaveProperty('totalStakingTokenAmount');
      expect(unstakingSummary).toHaveProperty('totalTokenRemaining');
      expect(unstakingSummary).toHaveProperty('totalCanClaimAmount');
      expect(Array.isArray(unstakingSummary.records)).toBe(true);
    });
  });

  describe('Transaction Building Tests', () => {
    it('should handle insufficient balance for approve transaction', async () => {
      const approveAmount = 1000000; // Large amount to trigger insufficient balance

      try {
        await stakingApiClient.tokenApprove(testOptions, TEST_ACCOUNT, approveAmount);
        // If we reach here, the test should fail
        expect(true).toBe(false);
      } catch (error: any) {
        expect(error.message).toContain('Insufficient balance');
      }
    });

    it('should handle insufficient balance for stake transaction', async () => {
      const stakeAmount = 1000000; // Large amount to trigger insufficient balance

      try {
        await stakingApiClient.stake(testOptions, TEST_ACCOUNT, stakeAmount);
        // If we reach here, the test should fail
        expect(true).toBe(false);
      } catch (error: any) {
        expect(error.message).toContain('Insufficient balance');
      }
    });

    it('should handle insufficient balance for unstake transaction', async () => {
      const unstakeAmount = 1000000; // Large amount to trigger insufficient balance

      try {
        await stakingApiClient.unstake(testOptions, TEST_ACCOUNT, unstakeAmount);
        // If we reach here, the test should fail
        expect(true).toBe(false);
      } catch (error: any) {
        expect(error.message).toContain('Insufficient balance');
      }
    });

    it('should handle insufficient approve amount for stake transaction', async () => {
      const stakeAmount = 100; // Reasonable amount but no approval

      try {
        await stakingApiClient.stake(testOptions, TEST_ACCOUNT, stakeAmount);
        // If we reach here, the test should fail
        expect(true).toBe(false);
      } catch (error: any) {
        expect(error.message).toContain('Insufficient approve amount');
      }
    });

    it('should build claim transaction successfully', async () => {
      const claimTx = await stakingApiClient.claim(testOptions, TEST_ACCOUNT);

      expect(claimTx).toHaveProperty('to');
      expect(claimTx).toHaveProperty('data');
    });
  });

  describe('Token Conversion Tests', () => {
    it('should calculate swap to staking token', async () => {
      const amount = 1000; // 1000 underlying tokens
      const stakingAmount = await stakingApiClient.swapToStakingToken(testOptions, amount);

      expect(stakingAmount).toBeGreaterThan(0);
    });

    it('should calculate swap to underlying token', async () => {
      const amount = 1000; // 1000 staking tokens
      const underlyingAmount = await stakingApiClient.swapToUnderlyingToken(testOptions, amount);

      expect(underlyingAmount).toBeGreaterThan(0);
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
        expect(error.message).toContain('Client not found for options');
      }
    });
  });

  describe('Performance Tests', () => {
    it('should complete multiple API calls within reasonable time', async () => {
      const startTime = Date.now();

      // Execute multiple API calls
      await Promise.all([
        stakingApiClient.getChainId(testOptions),
        stakingApiClient.tokenContractAddress(testOptions),
        stakingApiClient.stakingContractAddress(testOptions),
        stakingApiClient.isStakingPaused(testOptions),
        stakingApiClient.tokenBalance(testOptions, TEST_ACCOUNT),
      ]);

      const endTime = Date.now();
      const duration = endTime - startTime;

      // Expect to complete all calls within 5 seconds
      expect(duration).toBeLessThan(5000);
    });
  });
});
