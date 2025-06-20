// SPDX-License-Identifier: MIT
/// @solidity compiler-version 0.8.26
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {RewardsLibrary} from "../../../contracts/libs/reward.sol";

contract RewardsLibraryWrapper {
    function calcTotalRewardAtBlock(uint256 blocksPassed) public pure returns (uint256) {
        return RewardsLibrary.calcTotalRewardAtBlock(blocksPassed);
    }

    function expTaylor(uint256 x) public pure returns (uint256) {
        return RewardsLibrary.expTaylor(x);
    }
}

contract RewardsLibraryTest is Test {
    uint256 public constant totalAmount = 50_000_000 * 1e18;
    uint256 public constant totalBlocks = 7_776_000;
    uint256 public constant SCALE = 1e18;
    uint256 public constant LAMBDA_DECAY = 200 * 1e9;
    uint256 public constant TOTAL_FACTOR = 63_383_177;

    RewardsLibraryWrapper public wrapper;

    function setUp() public {
        wrapper = new RewardsLibraryWrapper();
    }

    function testCalcTotalReward_before_start_block() public view {
        uint256 reward = wrapper.calcTotalRewardAtBlock(0);
        assertTrue(reward == 0, "Reward should be 0");
    }

    function testCalcTotalReward_after_post_block() public view {
        uint256 reward = wrapper.calcTotalRewardAtBlock(totalBlocks);
        assertTrue(totalAmount - reward < 0.3 * 1e18, "Reward should be close to total amount");
    }

    function testCalcTotalRewardAtBlock_for_fuzz_blocks(uint256 offset) public view {
        offset = bound(offset, 0, totalBlocks);
        uint256 reward = wrapper.calcTotalRewardAtBlock(offset);
        assertTrue(reward >= 0, "Reward should be positive");
        assertTrue(reward <= totalAmount, "Reward should be less than total amount");
    }

    function testCalcTotalRewardAtBlock_invalid_blocks() public {
        vm.expectRevert("Reward: Invalid blocks passed");
        wrapper.calcTotalRewardAtBlock(1e9);
    }

    function testCalcTotalRewardAtBlock_max_valid_blocks() public view {
        uint256 reward = wrapper.calcTotalRewardAtBlock(1e9 - 1);
        assertTrue(reward > 0, "Reward should be positive for max valid blocks");
    }

    function testCalcTotalRewardAtBlock_monotonicity(uint256 offset) public view {
        offset = bound(offset, 0, totalBlocks - 4);
        uint256 totalReward1 = wrapper.calcTotalRewardAtBlock(offset);
        uint256 totalReward2 = wrapper.calcTotalRewardAtBlock(offset + 1);
        uint256 totalReward3 = wrapper.calcTotalRewardAtBlock(offset + 2);
        uint256 totalReward4 = wrapper.calcTotalRewardAtBlock(offset + 3);

        assertTrue(totalReward1 < totalReward2, "Reward should increase with blocks");
        assertTrue(totalReward2 < totalReward3, "Reward should increase with blocks");
        assertTrue(totalReward3 < totalReward4, "Reward should increase with blocks");

        uint256 reward1 = totalReward2 - totalReward1;
        uint256 reward2 = totalReward3 - totalReward2;
        uint256 reward3 = totalReward4 - totalReward3;

        assertTrue(reward1 > reward2, "Reward should decrease with blocks");
        assertTrue(reward2 > reward3, "Reward should decrease with blocks");
    }

    function testCalcTotalRewardAtBlock_monotonicity_fuzz(uint256 blocks1, uint256 blocks2) public view {
        blocks1 = bound(blocks1, 0, totalBlocks / 2);
        blocks2 = bound(blocks2, totalBlocks / 2 + 1, totalBlocks);

        uint256 reward1 = wrapper.calcTotalRewardAtBlock(blocks1);
        uint256 reward2 = wrapper.calcTotalRewardAtBlock(blocks2);

        assertTrue(reward1 < reward2, "Reward should be monotonically increasing");
    }

    function testCalcTotalRewardAtBlock_small_values() public view {
        uint256 reward1 = wrapper.calcTotalRewardAtBlock(1);
        uint256 reward10 = wrapper.calcTotalRewardAtBlock(10);
        uint256 reward100 = wrapper.calcTotalRewardAtBlock(100);

        assertTrue(reward1 > 0, "Reward should be positive for 1 block");
        assertTrue(reward10 > reward1, "Reward should increase");
        assertTrue(reward100 > reward10, "Reward should increase");
    }

    function testCalcTotalRewardAtBlock_large_values() public view {
        uint256 rewardHalf = wrapper.calcTotalRewardAtBlock(totalBlocks / 2);
        uint256 rewardThreeQuarters = wrapper.calcTotalRewardAtBlock((totalBlocks * 3) / 4);
        uint256 rewardFull = wrapper.calcTotalRewardAtBlock(totalBlocks);

        assertTrue(rewardHalf > 0, "Half way reward should be positive");
        assertTrue(rewardThreeQuarters > rewardHalf, "Three quarters should be more than half");
        assertTrue(rewardFull > rewardThreeQuarters, "Full should be more than three quarters");
    }

    function testExp_zero() public view {
        uint256 result = wrapper.expTaylor(0);
        assertTrue(result == SCALE, "exp(0) should equal 1 (SCALE)");
    }

    function testExp_small_values() public view {
        uint256 result1 = wrapper.expTaylor(SCALE / 10);
        uint256 result2 = wrapper.expTaylor(SCALE / 2);

        assertTrue(result1 > SCALE, "exp(0.1) should be greater than 1");
        assertTrue(result2 > result1, "exp(0.5) should be greater than exp(0.1)");
    }

    function testExp_monotonicity() public view {
        uint256 x1 = SCALE / 2;
        uint256 x2 = SCALE;
        uint256 x3 = SCALE * 2;

        uint256 result1 = wrapper.expTaylor(x1);
        uint256 result2 = wrapper.expTaylor(x2);
        uint256 result3 = wrapper.expTaylor(x3);

        assertTrue(result1 < result2, "exp should be monotonically increasing");
        assertTrue(result2 < result3, "exp should be monotonically increasing");
    }
}
