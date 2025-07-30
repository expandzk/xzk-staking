import { describe, it, expect, beforeEach } from '@jest/globals';
import { Config } from '../../../src/config/config';
import type { ClientOptions, StakingPeriod } from '../../../src/index';

describe('Config', () => {
  describe('constructor', () => {
    it('should create config for ethereum network', () => {
      const config = new Config('ethereum');
      expect(config.chainId).toBe(1);
      expect(config.decimals).toBe(18);
      expect(config.xzkContract).toBe('0xe8fC52b1bb3a40fd8889C0f8f75879676310dDf0');
      expect(config.vXZkContract).toBe('0x16aFFA80C65Fd7003d40B24eDb96f77b38dDC96A');
    });

    it('should create config for sepolia network', () => {
      const config = new Config('sepolia');
      expect(config.chainId).toBe(11155111);
      expect(config.decimals).toBe(18);
      expect(config.xzkContract).toBe('0x932161e47821c6F5AE69ef329aAC84be1E547e53');
      expect(config.vXZkContract).toBe('0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587');
      expect(config.providers).toHaveLength(9);
    });

    it('should throw error for unsupported network', () => {
      expect(() => new Config('unsupported')).toThrow('Unsupported network: unsupported');
    });
  });

  describe('tokenContractAddress', () => {
    let config: Config;

    beforeEach(() => {
      config = new Config('ethereum');
    });

    it('should return xzkContract for XZK token', () => {
      const options: ClientOptions = { tokenName: 'XZK', stakingPeriod: '365d' };
      expect(config.tokenContractAddress(options)).toBe(config.xzkContract);
    });

    it('should return vXZkContract for vXZK token', () => {
      const options: ClientOptions = { tokenName: 'vXZK', stakingPeriod: '365d' };
      expect(config.tokenContractAddress(options)).toBe(config.vXZkContract);
    });
  });

  describe('stakingContractAddress', () => {
    let config: Config;

    beforeEach(() => {
      config = new Config('dev'); // Using dev for non-zero addresses
    });

    it('should return zero addresses for Ethereum mainnet (not deployed)', () => {
      const mainnetConfig = new Config('ethereum');
      const testCases: ClientOptions[] = [
        { tokenName: 'XZK', stakingPeriod: '365d' },
        { tokenName: 'XZK', stakingPeriod: '180d' },
        { tokenName: 'XZK', stakingPeriod: '90d' },
        { tokenName: 'XZK', stakingPeriod: 'Flex' },
        { tokenName: 'vXZK', stakingPeriod: '365d' },
        { tokenName: 'vXZK', stakingPeriod: '180d' },
        { tokenName: 'vXZK', stakingPeriod: '90d' },
        { tokenName: 'vXZK', stakingPeriod: 'Flex' },
      ];

      testCases.forEach((options) => {
        expect(mainnetConfig.stakingContractAddress(options)).not.toBe(
          '0x0000000000000000000000000000000000000000',
        );
      });
    });
  });

  describe('totalDurationSeconds', () => {
    it('should return 3 years in seconds', () => {
      const config = new Config('ethereum');
      const expectedSeconds = 3 * 365 * 24 * 60 * 60; // 3 years
      expect(config.totalDurationSeconds()).toBe(expectedSeconds);
    });
  });

  describe('claimDelaySeconds', () => {
    it('should return 1 day in seconds', () => {
      const config = new Config('ethereum');
      const expectedSeconds = 24 * 60 * 60; // 1 day
      expect(config.claimDelaySeconds()).toBe(expectedSeconds);
    });
  });

  describe('stakingPeriodSeconds', () => {
    let config: Config;

    beforeEach(() => {
      config = new Config('ethereum');
    });

    it('should return 365 days for 365d period', () => {
      const expectedSeconds = 365 * 24 * 60 * 60;
      expect(config.stakingPeriodSeconds('365d')).toBe(expectedSeconds);
    });

    it('should return 180 days for 180d period', () => {
      const expectedSeconds = 180 * 24 * 60 * 60;
      expect(config.stakingPeriodSeconds('180d')).toBe(expectedSeconds);
    });

    it('should return 90 days for 90d period', () => {
      const expectedSeconds = 90 * 24 * 60 * 60;
      expect(config.stakingPeriodSeconds('90d')).toBe(expectedSeconds);
    });

    it('should return 0 for flexible period', () => {
      expect(config.stakingPeriodSeconds('Flex')).toBe(0);
    });

    it('should throw error for unsupported period', () => {
      expect(() => config.stakingPeriodSeconds('invalid' as StakingPeriod)).toThrow(
        'Unsupported staking period: invalid',
      );
    });
  });

  describe('getters', () => {
    it('should return correct values for all getters', () => {
      const config = new Config('sepolia');

      expect(config.chainId).toBe(11155111);
      expect(config.decimals).toBe(18);
      expect(config.xzkContract).toBe('0x932161e47821c6F5AE69ef329aAC84be1E547e53');
      expect(config.vXZkContract).toBe('0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587');
      expect(Array.isArray(config.providers)).toBe(true);
      expect(config.providers.length).toBeGreaterThan(0);
    });
  });
});
