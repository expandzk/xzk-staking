// SPDX-License-Identifier: MIT
/// @solidity compiler-version 0.8.26
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {RewardsLibrary} from "../../../contracts/libs/reward.sol";
import {console} from "forge-std/console.sol";

contract RewardsLibraryTest is Test {
    uint256 public constant totalAmount = 50_000_000 * 1e18;
    int256 public constant totalFactor = 1_094_396_414 * 1e9;
    uint256 public constant totalBlocks = 7_776_000;

    function setUp() public {}

    function testCalcTotalReward_before_start_block() public pure {
        uint256 reward = RewardsLibrary.calcTotalRewardAtBlock(0, totalFactor);
        assertTrue(reward == 0, "Reward should be 0");
    }

    function testCalcTotalReward_after_post_block() public pure {
        uint256 reward = RewardsLibrary.calcTotalRewardAtBlock(int256(totalBlocks), totalFactor);
        assertTrue(totalAmount - reward < 0.03 * 1e18, "Reward should be close to total amount");
    }

    function testCalcTotalRewardAtBlock_for_fuzz_blocks(int256 offset) public pure {
        offset = int256(bound(uint256(offset), 0, totalBlocks));
        uint256 reward = RewardsLibrary.calcTotalRewardAtBlock(offset, totalFactor);
        assertTrue(reward >= 0, "Reward should be positive");
        assertTrue(reward <= totalAmount, "Reward should be less than total amount");
    }
}
