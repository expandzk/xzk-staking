import { expect } from 'chai';
import { ethers } from 'hardhat';
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';
import { writeFileSync } from 'fs';

describe('MystikoStaking', function () {
  let staking360: any;
  let staking180: any;
  let staking90: any;
  let stakingFlexible: any;
  let mockToken: any;
  let mockVoteToken: any;
  let owner: HardhatEthersSigner;
  let addr1: HardhatEthersSigner;
  let addr2: HardhatEthersSigner;

  const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';

  beforeEach(async function () {
    // Get signers
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy contract
    mockToken = await ethers.deployContract('MockToken');
    await mockToken.waitForDeployment();
    const mockTokenAddress = await mockToken.getAddress();

    mockVoteToken = await ethers.deployContract('MockVoteToken', [mockTokenAddress]);
    await mockVoteToken.waitForDeployment();
    const mockVoteTokenAddress = await mockVoteToken.getAddress();

    const startBlock = (await ethers.provider.getBlockNumber()) + 10000;
    const MystikoStaking = await ethers.getContractFactory('MystikoStaking');

    staking360 = await MystikoStaking.deploy(
      mockVoteTokenAddress,
      'Mystiko Staking Vote Token 360D',
      'sVXZK-360D',
      4,
      startBlock,
    );
    await staking360.waitForDeployment();

    staking180 = await MystikoStaking.deploy(
      mockVoteTokenAddress,
      'Mystiko Staking Vote Token 180D',
      'sVXZK-180D',
      3,
      startBlock,
    );
    await staking180.waitForDeployment();

    staking90 = await MystikoStaking.deploy(
      mockVoteTokenAddress,
      'Mystiko Staking Vote Token 90D',
      'sVXZK-90D',
      2,
      startBlock,
    );
    await staking90.waitForDeployment();

    stakingFlexible = await MystikoStaking.deploy(
      mockVoteTokenAddress,
      'Mystiko Staking Vote Token Flexible',
      'sVXZK-FLEX',
      1,
      startBlock,
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

      const blockNumber = Number(await ethers.provider.getBlockNumber());
      const startBlock = Number(await staking360.startBlock());
      const totalBlocks = Number(await staking360.totalBlocks());
      const endBlock = startBlock + totalBlocks;

      // Create array to store data
      const rewardData: {
        block: number;
        reward360: string;
        reward180: string;
        reward90: string;
        rewardFlexible: string;
      }[] = [];

      // Pre-start blocks
      for (let i = blockNumber; i < startBlock; i += 1000) {
        const currentBlock = await ethers.provider.getBlockNumber();
        expect(currentBlock).to.equal(i);
        const reward360 = await staking360.currentTotalReward();
        const reward180 = await staking180.currentTotalReward();
        const reward90 = await staking90.currentTotalReward();
        const rewardFlexible = await stakingFlexible.currentTotalReward();
        rewardData.push({
          block: currentBlock,
          reward360: reward360.toString(),
          reward180: reward180.toString(),
          reward90: reward90.toString(),
          rewardFlexible: rewardFlexible.toString(),
        });
        if (i + 1000 < startBlock) {
          await ethers.provider.send('hardhat_mine', [1000]);
        }
      }

      // Set block to startBlock before active rewards period
      const currentBlockBeforeActive = await ethers.provider.getBlockNumber();
      await ethers.provider.send('hardhat_mine', [startBlock - currentBlockBeforeActive]);
      const currentBlockAfterActive = await ethers.provider.getBlockNumber();
      expect(currentBlockAfterActive).to.equal(startBlock);

      // Active rewards period
      for (let i = startBlock; i < endBlock; i += 1000) {
        const currentBlock = await ethers.provider.getBlockNumber();
        expect(currentBlock).to.equal(i);
        const reward360 = await staking360.currentTotalReward();
        const reward180 = await staking180.currentTotalReward();
        const reward90 = await staking90.currentTotalReward();
        const rewardFlexible = await stakingFlexible.currentTotalReward();
        rewardData.push({
          block: currentBlock,
          reward360: reward360.toString(),
          reward180: reward180.toString(),
          reward90: reward90.toString(),
          rewardFlexible: rewardFlexible.toString(),
        });
        if (i + 1000 < endBlock) {
          await ethers.provider.send('hardhat_mine', [1000]);
        }
      }

      // Set block to totalBlocks before post-total blocks
      const currentBlockBeforePost = await ethers.provider.getBlockNumber();
      await ethers.provider.send('hardhat_mine', [endBlock - currentBlockBeforePost]);
      const currentBlockAfterPost = await ethers.provider.getBlockNumber();
      expect(currentBlockAfterPost).to.equal(endBlock);

      // Post-total blocks rewards
      for (let i = endBlock; i < endBlock + 3000; i += 100) {
        const currentBlock = await ethers.provider.getBlockNumber();
        expect(currentBlock).to.equal(i);
        const reward360 = await staking360.currentTotalReward();
        const reward180 = await staking180.currentTotalReward();
        const reward90 = await staking90.currentTotalReward();
        const rewardFlexible = await stakingFlexible.currentTotalReward();
        rewardData.push({
          block: currentBlock,
          reward360: reward360.toString(),
          reward180: reward180.toString(),
          reward90: reward90.toString(),
          rewardFlexible: rewardFlexible.toString(),
        });
        await ethers.provider.send('hardhat_mine', [100]);
      }

      // Convert data to CSV format
      const csvContent = [
        'Block,Reward360,Reward180,Reward90,RewardFlexible\n',
        ...rewardData.map(
          (data) =>
            `${data.block},${data.reward360},${data.reward180},${data.reward90},${data.rewardFlexible}\n`,
        ),
      ].join('');

      // Write to CSV file
      writeFileSync('staking-rewards.csv', csvContent);
    });
  });
});
