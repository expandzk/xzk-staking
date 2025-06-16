// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {MystikoStaking} from "../../contracts/MystikoStaking.sol";
import {MockToken} from "../../contracts/mocks/MockToken.sol";
import {MockVoteToken} from "../../contracts/mocks/MockVoteToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingCalcTest is Test {
    MystikoStaking public stakingFlexible;
    MockToken public mockToken;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);
        mockToken = new MockToken();

        stakingFlexible = new MystikoStaking(
            mockToken,
            "Mystiko Staking Vote Token Flexible",
            "sVXZK-FLEX",
            0,
            1,
            block.number + 10000
        );
        vm.stopPrank();
    }

    function test_InitialStakingCalculations() public view {
        uint256 amount = 100 ether;

        // Test initial staking calculation (no tokens staked)
        uint256 stakedAmount = stakingFlexible.swapToStakingToken(amount);
        assertEq(stakedAmount, amount, "Initial staking should be 1:1");

        // Test unstaking calculation with no tokens staked
        uint256 unstakedAmount = stakingFlexible.swapToUnderlyingToken(amount);
        assertEq(unstakedAmount, amount, "Initial unstaking should be 1:1");
    }

    function test_StakingCalculationsAfterStake() public {
        uint256 amount = 100 ether;

        // Mint and approve tokens
        vm.startPrank(owner);
        mockToken.mint(user1, amount);
        vm.stopPrank();

        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), amount);
        stakingFlexible.stake(amount);

        // Test staking calculation after initial stake
        uint256 secondAmount = 50 ether;
        uint256 stakedAmount = stakingFlexible.swapToStakingToken(secondAmount);
        assertEq(stakedAmount, secondAmount, "Staking should still be 1:1 as no rewards yet");

        // Test unstaking calculation
        uint256 stakedBalance = stakingFlexible.balanceOf(user1);
        uint256 unstakedAmount = stakingFlexible.swapToUnderlyingToken(stakedBalance);
        assertEq(unstakedAmount, amount, "Unstaking should return original amount as no rewards yet");
        vm.stopPrank();
    }

    function test_StakingCalculationsWithRewards() public {
        uint256 amount = 100 ether;

        // Mint and approve tokens
        vm.startPrank(owner);
        mockToken.mint(user1, amount);
        vm.stopPrank();

        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), amount);
        stakingFlexible.stake(amount);

        // Move to start block to begin rewards
        uint256 startBlock = stakingFlexible.START_BLOCK();
        vm.roll(startBlock + 1);

        // Test staking calculation after rewards start
        uint256 secondAmount = 25 ether;
        uint256 stakedAmount = stakingFlexible.swapToStakingToken(secondAmount);
        assertLt(stakedAmount, secondAmount, "Staked amount should be less due to rewards");

        // Test unstaking calculation with rewards
        uint256 stakedBalance = stakingFlexible.balanceOf(user1);
        uint256 unstakedAmount = stakingFlexible.swapToUnderlyingToken(stakedBalance);
        assertGt(unstakedAmount, amount, "Unstaked amount should be greater due to rewards");
        vm.stopPrank();
    }

    function test_StakingCalculationsWithSmallAmounts() public view {
        uint256 smallAmount = 0.000001 ether;

        // Test staking calculation with small amount
        uint256 stakedAmount = stakingFlexible.swapToStakingToken(smallAmount);
        assertGt(stakedAmount, 0, "Small amount staking should work");

        // Test unstaking calculation with small amount
        uint256 unstakedAmount = stakingFlexible.swapToUnderlyingToken(smallAmount);
        assertGt(unstakedAmount, 0, "Small amount unstaking should work");
    }

    function test_StakingCalculationsWithZeroAmount() public view {
        // Test staking calculation with zero amount
        uint256 stakedAmount = stakingFlexible.swapToStakingToken(0);
        assertEq(stakedAmount, 0, "Zero amount staking should return zero");

        // Test unstaking calculation with zero amount
        uint256 unstakedAmount = stakingFlexible.swapToUnderlyingToken(0);
        assertEq(unstakedAmount, 0, "Zero amount unstaking should return zero");
    }

    function test_ConversionConsistency() public {
        uint256 amount = 100 ether;

        // Mint and approve tokens
        vm.startPrank(owner);
        mockToken.mint(user1, amount);
        vm.stopPrank();

        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), amount);
        stakingFlexible.stake(amount);

        // Move to reward block
        uint256 rewardBlock = stakingFlexible.START_BLOCK() + 1000;
        vm.roll(rewardBlock);

        // Test conversion consistency
        uint256 stakedAmount = stakingFlexible.swapToStakingToken(amount);
        uint256 unstakedAmount = stakingFlexible.swapToUnderlyingToken(stakedAmount);

        // Allow for small rounding differences
        uint256 difference = unstakedAmount > amount ? unstakedAmount - amount : amount - unstakedAmount;
        assertLt(difference, 0.000001 ether, "Conversion should be consistent within rounding error");
        vm.stopPrank();
    }
}
