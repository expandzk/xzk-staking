import { expect } from 'chai';
import { ethers } from 'hardhat';
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';
import { writeFileSync } from 'fs';

describe('XzkStaking', function () {
  let staking360: any;
  let staking180: any;
  let staking90: any;
  let stakingFlexible: any;
  let mockToken: any;
  let mockVoteToken: any;
  let owner: HardhatEthersSigner;
  let addr1: HardhatEthersSigner;
  let addr2: HardhatEthersSigner;
  let dao: HardhatEthersSigner;

  const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';

  beforeEach(async function () {
    // Get signers
    [owner, addr1, addr2, dao] = await ethers.getSigners();

    // Deploy contract
    mockToken = await ethers.deployContract('MockToken');
    await mockToken.waitForDeployment();
    const mockTokenAddress = await mockToken.getAddress();

    mockVoteToken = await ethers.deployContract('MockVoteToken', [mockTokenAddress]);
    await mockVoteToken.waitForDeployment();
    const mockVoteTokenAddress = await mockVoteToken.getAddress();

    const latestBlock = await ethers.provider.getBlock('latest');
    if (!latestBlock) {
      throw new Error('Latest block not found');
    }
    const startTimestamp = latestBlock.timestamp + 5 * 24 * 3600 + 3600 * 4;
    const XzkStaking = await ethers.getContractFactory('XzkStaking');

    staking360 = await XzkStaking.deploy(
      dao.address,
      owner.address,
      mockVoteTokenAddress,
      'Mystiko Staking Vote Token 365D',
      'svXZK-365D',
      365 * 24 * 3600,
      5500,
      startTimestamp,
    );
    await staking360.waitForDeployment();

    staking180 = await XzkStaking.deploy(
      dao.address,
      owner.address,
      mockVoteTokenAddress,
      'Mystiko Staking Vote Token 180D',
      'svXZK-180D',
      180 * 24 * 3600,
      2700,
      startTimestamp,
    );
    await staking180.waitForDeployment();

    staking90 = await XzkStaking.deploy(
      dao.address,
      owner.address,
      mockVoteTokenAddress,
      'Mystiko Staking Vote Token 90D',
      'svXZK-90D',
      90 * 24 * 3600,
      1300,
      startTimestamp,
    );
    await staking90.waitForDeployment();

    stakingFlexible = await XzkStaking.deploy(
      dao.address,
      owner.address,
      mockVoteTokenAddress,
      'Mystiko Staking Vote Token Flexible',
      'svXZK-FLEX',
      0,
      500,
      startTimestamp,
    );
    await stakingFlexible.waitForDeployment();
  });

  describe('Deployment', function () {
    it('Should set the right owner', async function () {
      expect(await staking360.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.equal(true);
      expect(await staking180.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.equal(true);
      expect(await staking90.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.equal(true);
      expect(await stakingFlexible.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.equal(true);
    });
  });

  describe('Calculate staking rewards and save to CSV', function () {
    it('Test all rewards', async function () {
      this.timeout(1200000); // Increase timeout to 1200 seconds

      const latestBlock = await ethers.provider.getBlock('latest');
      if (!latestBlock) {
        throw new Error('Latest block not found');
      }
      const latestTimestamp = latestBlock.timestamp;

      const startTimestamp = Number(await staking360.START_TIME());
      const totalDuration = Number(await staking360.totalDurationSeconds());
      const endTimestamp = startTimestamp + totalDuration;

      // Create array to store data
      const rewardData: {
        blockTimestamp: number;
        reward360: string;
        reward180: string;
        reward90: string;
        rewardFlexible: string;
      }[] = [];

      // Pre-start blocks - use smaller intervals to avoid memory issues
      let i = latestTimestamp + 5 * 24 * 3600;
      for (; i < startTimestamp; i += 3600) {
        await ethers.provider.send('evm_setNextBlockTimestamp', [i]);
        await ethers.provider.send('hardhat_mine', [1]);
        const reward360 = await staking360.totalRewardAt(i);
        const reward180 = await staking180.totalRewardAt(i);
        const reward90 = await staking90.totalRewardAt(i);
        const rewardFlexible = await stakingFlexible.totalRewardAt(i);
        rewardData.push({
          blockTimestamp: i - startTimestamp,
          reward360: reward360.toString(),
          reward180: reward180.toString(),
          reward90: reward90.toString(),
          rewardFlexible: rewardFlexible.toString(),
        });
      }

      i = startTimestamp;
      // Active rewards period - use larger intervals to reduce memory usage
      for (; i <= endTimestamp; i += 3600) {
        await ethers.provider.send('evm_setNextBlockTimestamp', [i]);
        await ethers.provider.send('hardhat_mine', [1]);
        expect((i - startTimestamp) % 3600).to.equal(0);
        const reward360 = await staking360.totalRewardAt(i);
        const reward180 = await staking180.totalRewardAt(i);
        const reward90 = await staking90.totalRewardAt(i);
        const rewardFlexible = await stakingFlexible.totalRewardAt(i);
        rewardData.push({
          blockTimestamp: i - startTimestamp,
          reward360: reward360.toString(),
          reward180: reward180.toString(),
          reward90: reward90.toString(),
          rewardFlexible: rewardFlexible.toString(),
        });
      }

      i = endTimestamp + 1;
      const postEndTimestamp = endTimestamp + 3600 * 30;
      for (; i < postEndTimestamp; i += 3600) {
        await ethers.provider.send('evm_setNextBlockTimestamp', [i]);
        await ethers.provider.send('hardhat_mine', [1]);
        const reward360 = await staking360.totalRewardAt(i);
        const reward180 = await staking180.totalRewardAt(i);
        const reward90 = await staking90.totalRewardAt(i);
        const rewardFlexible = await stakingFlexible.totalRewardAt(i);
        rewardData.push({
          blockTimestamp: i - startTimestamp,
          reward360: reward360.toString(),
          reward180: reward180.toString(),
          reward90: reward90.toString(),
          rewardFlexible: rewardFlexible.toString(),
        });
      }

      // Convert data to CSV format - fix the property name
      const csvContent = [
        'BlockTimestamp,Reward360,Reward180,Reward90,RewardFlexible\n',
        ...rewardData.map(
          (data) =>
            `${data.blockTimestamp},${data.reward360},${data.reward180},${data.reward90},${data.rewardFlexible}\n`,
        ),
      ].join('');

      // Write to CSV file
      writeFileSync('staking-rewards.csv', csvContent);
    });
  });
});
