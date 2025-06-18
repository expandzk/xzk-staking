// SPDX-License-Identifier: MIT
/// @solidity compiler-version 0.8.26
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {RewardsLibrary} from "../../../contracts/libs/reward.sol";

contract RewardsLibraryTest is Test {
    uint256 public constant totalAmount = 50_000_000 * 1e18;
    uint256 public constant totalBlocks = 7_776_000;

    function setUp() public {}

    function testCalcTotalReward_before_start_block() public pure {
        uint256 reward = RewardsLibrary.calcTotalRewardAtBlock(0);
        assertTrue(reward == 0, "Reward should be 0");
    }

    function testCalcTotalReward_after_post_block() public pure {
        uint256 reward = RewardsLibrary.calcTotalRewardAtBlock(totalBlocks);
        assertTrue(totalAmount - reward < 0.3 * 1e18, "Reward should be close to total amount");
    }

    function testCalcTotalRewardAtBlock_for_fuzz_blocks(uint256 offset) public pure {
        offset = bound(offset, 0, totalBlocks);
        uint256 reward = RewardsLibrary.calcTotalRewardAtBlock(offset);
        assertTrue(reward >= 0, "Reward should be positive");
        assertTrue(reward <= totalAmount, "Reward should be less than total amount");
    }
}
