import { describe, it, expect, beforeEach } from '@jest/globals';
import { Config } from '../../src/config/config';
import type { ClientOptions, StakingPeriod } from '../../src/index';

describe('Config', () => {
    describe('constructor', () => {
        it('should create config for supported chain ID 1 (Ethereum mainnet)', () => {
            const config = new Config(1);
            expect(config.chainId).toBe(1);
            expect(config.decimals).toBe(18);
            expect(config.xzkContract).toBe('0xe8fC52b1bb3a40fd8889C0f8f75879676310dDf0');
            expect(config.vXZkContract).toBe('0x16aFFA80C65Fd7003d40B24eDb96f77b38dDC96A');
            expect(config.providers).toHaveLength(6);
        });

        it('should create config for supported chain ID 11155111 (Sepolia testnet)', () => {
            const config = new Config(11155111);
            expect(config.chainId).toBe(11155111);
            expect(config.decimals).toBe(18);
            expect(config.xzkContract).toBe('0x932161e47821c6F5AE69ef329aAC84be1E547e53');
            expect(config.vXZkContract).toBe('0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587');
            expect(config.providers).toHaveLength(2);
        });

        it('should throw error for unsupported chain ID', () => {
            expect(() => new Config(999)).toThrow('Unsupported chain ID: 999');
        });
    });

    describe('tokenContractAddress', () => {
        let config: Config;

        beforeEach(() => {
            config = new Config(1);
        });

        it('should return xzkContract for XZK token', () => {
            const options: ClientOptions = { tokenName: 'XZK', stakingPeriod: '365d' };
            expect(config.tokenContractAddress(options)).toBe(config.xzkContract);
        });

        it('should return vXZkContract for VXZK token', () => {
            const options: ClientOptions = { tokenName: 'VXZK', stakingPeriod: '365d' };
            expect(config.tokenContractAddress(options)).toBe(config.vXZkContract);
        });
    });

    describe('stakingContractAddress', () => {
        let config: Config;

        beforeEach(() => {
            config = new Config(11155111); // Using Sepolia for non-zero addresses
        });

        it('should return correct staking contract addresses for Sepolia', () => {
            const expectedAddresses = {
                'XZK-365d': '0x9cC6b3fE97c1F03eF74f369e61A2e87DD83B2EDF',
                'XZK-180d': '0xe4D932b62783953FE693069a09308f27DA8140c9',
                'XZK-90d': '0x1C91E9b6A81F92FEab337e206Bf218a30Bf581E2',
                'XZK-Flex': '0x59bAe9b5c007Cb0e06bad64E4DD69788A51321BA',
                'VXZK-365d': '0xb5971b52775735CcfD361251FF3982b0a71CD971',
                'VXZK-180d': '0x97DFa99097C5b8A359B947c63b131022ac33606d',
                'VXZK-90d': '0xd72627C7168434DC4a8f9Fa9e3E09951814bDeaE',
                'VXZK-Flex': '0x5958D56dB3ED16471989359005beB9bE5d430AAd',
            };

            Object.entries(expectedAddresses).forEach(([key, expectedAddress]) => {
                const [tokenName, stakingPeriod] = key.split('-') as ['XZK' | 'VXZK', StakingPeriod];
                const options: ClientOptions = { tokenName, stakingPeriod };
                expect(config.stakingContractAddress(options)).toBe(expectedAddress);
            });
        });

        it('should return zero addresses for Ethereum mainnet (not deployed)', () => {
            const mainnetConfig = new Config(1);
            const testCases: ClientOptions[] = [
                { tokenName: 'XZK', stakingPeriod: '365d' },
                { tokenName: 'XZK', stakingPeriod: '180d' },
                { tokenName: 'XZK', stakingPeriod: '90d' },
                { tokenName: 'XZK', stakingPeriod: 'Flex' },
                { tokenName: 'VXZK', stakingPeriod: '365d' },
                { tokenName: 'VXZK', stakingPeriod: '180d' },
                { tokenName: 'VXZK', stakingPeriod: '90d' },
                { tokenName: 'VXZK', stakingPeriod: 'Flex' },
            ];

            testCases.forEach((options) => {
                expect(mainnetConfig.stakingContractAddress(options)).toBe('0x0000000000000000000000000000000000000000');
            });
        });
    });

    describe('totalDurationSeconds', () => {
        it('should return 3 years in seconds', () => {
            const config = new Config(1);
            const expectedSeconds = 3 * 365 * 24 * 60 * 60; // 3 years
            expect(config.totalDurationSeconds()).toBe(expectedSeconds);
        });
    });

    describe('claimDelaySeconds', () => {
        it('should return 1 day in seconds', () => {
            const config = new Config(1);
            const expectedSeconds = 24 * 60 * 60; // 1 day
            expect(config.claimDelaySeconds()).toBe(expectedSeconds);
        });
    });

    describe('stakingPeriodSeconds', () => {
        let config: Config;

        beforeEach(() => {
            config = new Config(1);
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
            expect(() => config.stakingPeriodSeconds('invalid' as StakingPeriod))
                .toThrow('Unsupported staking period: invalid');
        });
    });

    describe('getters', () => {
        it('should return correct values for all getters', () => {
            const config = new Config(11155111);

            expect(config.chainId).toBe(11155111);
            expect(config.decimals).toBe(18);
            expect(config.xzkContract).toBe('0x932161e47821c6F5AE69ef329aAC84be1E547e53');
            expect(config.vXZkContract).toBe('0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587');
            expect(Array.isArray(config.providers)).toBe(true);
            expect(config.providers.length).toBeGreaterThan(0);
        });
    });
});
