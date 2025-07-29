// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {Constants} from "../../contracts/libs/constant.sol";
import {XzkStaking} from "../../contracts/XzkStaking.sol";
import {MockToken} from "../../contracts/mocks/MockToken.sol";
import {MockVoteToken} from "../../contracts/mocks/MockVoteToken.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MystikoGovernorRegistry} from
    "../../lib/mystiko-governance/packages/contracts/contracts/impl/MystikoGovernorRegistry.sol";

contract StakingSwapTest is Test {
    XzkStaking public stakingFlexible;
    MockToken public mockToken;
    address public owner;
    address public user1;
    address public user2;
    address public dao;
    MystikoGovernorRegistry public daoRegistry;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        dao = makeAddr("dao");

        vm.startPrank(owner);
        mockToken = new MockToken();
        daoRegistry = new MystikoGovernorRegistry();
        daoRegistry.transferOwnerToDAO(dao);

        stakingFlexible = new XzkStaking(
            address(daoRegistry),
            owner,
            mockToken,
            "Mystiko Staking Vote Token 180D",
            "svXZK-180D",
            180 days,
            1500,
            block.timestamp + 5 days
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
        vm.warp(stakingFlexible.START_TIME() + 1);

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
        vm.warp(stakingFlexible.START_TIME() + 1 seconds);

        // Test conversion consistency
        uint256 stakedAmount = stakingFlexible.swapToStakingToken(amount);
        uint256 unstakedAmount = stakingFlexible.swapToUnderlyingToken(stakedAmount);

        // Allow for small rounding differences
        uint256 difference = unstakedAmount > amount ? unstakedAmount - amount : amount - unstakedAmount;
        assertLt(difference, 0.000001 ether, "Conversion should be consistent within rounding error");
        vm.stopPrank();
    }

    function test_SwapWithMultipleStakers() public {
        uint256 amount = 100 ether;

        // Mint and approve tokens for both users
        vm.startPrank(owner);
        mockToken.mint(user1, amount);
        mockToken.mint(user2, amount);
        vm.stopPrank();

        // User1 stakes
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), amount);
        stakingFlexible.stake(amount);
        vm.stopPrank();

        // Move to reward period
        vm.warp(stakingFlexible.START_TIME() + 365 days);

        // User2 stakes (should get less staking tokens due to existing rewards)
        vm.startPrank(user2);
        mockToken.approve(address(stakingFlexible), amount);
        stakingFlexible.stake(amount);
        vm.stopPrank();

        // User2 should have fewer staking tokens than user1
        uint256 user1Balance = stakingFlexible.balanceOf(user1);
        uint256 user2Balance = stakingFlexible.balanceOf(user2);
        assertEq(user1Balance, amount, "User1 should have original amount");
        assertLt(user2Balance, amount, "User2 should have less due to rewards");

        // Test swap calculations
        uint256 user1UnstakeAmount = stakingFlexible.swapToUnderlyingToken(user1Balance);
        uint256 user2UnstakeAmount = stakingFlexible.swapToUnderlyingToken(user2Balance);

        assertGt(user1UnstakeAmount, amount, "User1 should get more due to rewards");

        // Allow for small precision loss due to rounding
        uint256 difference = amount > user2UnstakeAmount ? amount - user2UnstakeAmount : user2UnstakeAmount - amount;
        assertLt(difference, 0.000001 ether, "User2 should get original amount within precision error");
    }

    function test_SwapWithRewardGrowth() public {
        uint256 amount = 100 ether;

        // Mint and approve tokens
        vm.startPrank(owner);
        mockToken.mint(user1, amount);
        vm.stopPrank();

        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), amount);
        stakingFlexible.stake(amount);

        uint256 totalDuration = Constants.TOTAL_DURATION_SECONDS;
        // Test swap at different reward levels
        uint256[] memory timestamps = new uint256[](3);
        timestamps[0] = stakingFlexible.START_TIME() + totalDuration / 4;
        timestamps[1] = stakingFlexible.START_TIME() + totalDuration / 2;
        timestamps[2] = stakingFlexible.START_TIME() + totalDuration;

        uint256[] memory stakingAmounts = new uint256[](3);
        uint256[] memory unstakingAmounts = new uint256[](3);

        for (uint256 i = 0; i < 3; i++) {
            vm.warp(timestamps[i]);

            stakingAmounts[i] = stakingFlexible.swapToStakingToken(amount);
            unstakingAmounts[i] = stakingFlexible.swapToUnderlyingToken(amount);
        }

        // Staking amounts should decrease over time (more rewards = less staking tokens for same input)
        assertGt(stakingAmounts[0], stakingAmounts[1], "Staking amount should decrease with more rewards");
        assertGt(stakingAmounts[1], stakingAmounts[2], "Staking amount should decrease with more rewards");

        // Unstaking amounts should increase over time (more rewards = more underlying tokens for same staking tokens)
        assertLt(unstakingAmounts[0], unstakingAmounts[1], "Unstaking amount should increase with more rewards");
        assertLt(unstakingAmounts[1], unstakingAmounts[2], "Unstaking amount should increase with more rewards");

        vm.stopPrank();
    }

    function test_SwapEdgeCases() public {
        // Test with very large amounts
        uint256 largeAmount = 1_000_000 ether;
        uint256 stakedAmount = stakingFlexible.swapToStakingToken(largeAmount);
        uint256 unstakedAmount = stakingFlexible.swapToUnderlyingToken(largeAmount);

        assertEq(stakedAmount, largeAmount, "Large amount staking should work");
        assertEq(unstakedAmount, largeAmount, "Large amount unstaking should work");

        // Test with maximum uint256
        uint256 maxAmount = type(uint256).max;
        uint256 maxStakedAmount = stakingFlexible.swapToStakingToken(maxAmount);
        uint256 maxUnstakedAmount = stakingFlexible.swapToUnderlyingToken(maxAmount);

        assertEq(maxStakedAmount, maxAmount, "Max amount staking should work");
        assertEq(maxUnstakedAmount, maxAmount, "Max amount unstaking should work");
    }
}
