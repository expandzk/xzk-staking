// SPDX-License-Identifier: MIT
/// @solidity compiler-version 0.8.26
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {RewardsLibrary} from "../../../contracts/libs/Reward.sol";
import {console} from "forge-std/console.sol";

contract RewardsLibraryWrapper {
    function calcTotalReward(uint256 timePassed) public pure returns (uint256) {
        return RewardsLibrary.calcTotalReward(timePassed);
    }

    function expTaylor(uint256 x) public pure returns (uint256) {
        return RewardsLibrary.expTaylor(x);
    }
}

contract RewardsLibraryTest is Test {
    uint256 public constant totalAmount = 50_000_000 * 1e18;
    uint256 public constant totalTime = 3 * 365 days;
    uint256 public constant SCALE = 1e18;

    RewardsLibraryWrapper public wrapper;

    function setUp() public {
        wrapper = new RewardsLibraryWrapper();
    }

    function testCalcTotalReward_before_start_time() public view {
        uint256 reward = wrapper.calcTotalReward(0);
        assertTrue(reward == 0, "Reward should be 0");
    }

    function testCalcTotalReward_after_post_time() public view {
        uint256 reward = wrapper.calcTotalReward(totalTime);
        console.log("reward", reward);
        assertTrue(totalAmount - reward < 0.0001 * 1e18, "Reward should be close to total amount");
    }

    function testCalcTotalReward_for_fuzz_time(uint256 offset) public view {
        offset = bound(offset, 0, totalTime);
        uint256 reward = wrapper.calcTotalReward(offset);
        assertTrue(reward >= 0, "Reward should be positive");
        assertTrue(reward <= totalAmount, "Reward should be less than total amount");
    }

    function testCalcTotalReward_invalid_time() public {
        vm.expectRevert("Reward: Invalid time passed");
        wrapper.calcTotalReward(10 * 365 days);
    }

    function testCalcTotalReward_max_valid_time() public view {
        uint256 reward = wrapper.calcTotalReward(10 * 365 days - 1);
        assertTrue(reward > 0, "Reward should be positive for max valid time");
    }

    function testCalcTotalReward_monotonicity(uint256 offset) public view {
        offset = bound(offset, 0, totalTime - 4);
        uint256 totalReward1 = wrapper.calcTotalReward(offset);
        uint256 totalReward2 = wrapper.calcTotalReward(offset + 1);
        uint256 totalReward3 = wrapper.calcTotalReward(offset + 2);
        uint256 totalReward4 = wrapper.calcTotalReward(offset + 3);

        assertTrue(totalReward1 < totalReward2, "Reward should increase with time");
        assertTrue(totalReward2 < totalReward3, "Reward should increase with time");
        assertTrue(totalReward3 < totalReward4, "Reward should increase with time");

        uint256 reward1 = totalReward2 - totalReward1;
        uint256 reward2 = totalReward3 - totalReward2;
        uint256 reward3 = totalReward4 - totalReward3;

        assertTrue(reward1 > reward2, "Reward should decrease with blocks");
        assertTrue(reward2 > reward3, "Reward should decrease with blocks");
    }

    function testCalcTotalReward_monotonicity_fuzz(uint256 time1, uint256 time2) public view {
        time1 = bound(time1, 0, totalTime / 2);
        time2 = bound(time2, totalTime / 2 + 1, totalTime);

        uint256 reward1 = wrapper.calcTotalReward(time1);
        uint256 reward2 = wrapper.calcTotalReward(time2);

        assertTrue(reward1 < reward2, "Reward should be monotonically increasing");
    }

    function testCalcTotalReward_small_values() public view {
        uint256 reward1 = wrapper.calcTotalReward(1);
        uint256 reward10 = wrapper.calcTotalReward(10);
        uint256 reward100 = wrapper.calcTotalReward(100);

        assertTrue(reward1 > 0, "Reward should be positive for 1 second");
        assertTrue(reward10 > reward1, "Reward should increase");
        assertTrue(reward100 > reward10, "Reward should increase");
    }

    function testCalcTotalReward_large_values() public view {
        uint256 rewardHalf = wrapper.calcTotalReward(totalTime / 2);
        uint256 rewardThreeQuarters = wrapper.calcTotalReward((totalTime * 3) / 4);
        uint256 rewardFull = wrapper.calcTotalReward(totalTime);

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
