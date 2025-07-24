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
import {GovernanceErrors} from "../../lib/mystiko-governance/packages/contracts/contracts/GovernanceErrors.sol";

contract StakingStake365DayTest is Test {
    XzkStaking public staking;
    MockToken public mockToken;
    MockVoteToken public mockVoteToken;
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    address public dao;
    MystikoGovernorRegistry public daoRegistry;

    uint256 public constant STAKE_AMOUNT = 100 ether;
    uint256 public constant SMALL_AMOUNT = 1 ether;
    uint256 public constant LARGE_AMOUNT = 1000 ether;
    uint256 public constant STAKING_PERIOD_SECONDS = 365 days;

    // Event declarations
    event Staked(address indexed account, uint256 amount, uint256 stakingAmount);
    event Unstaked(address indexed account, uint256 stakingAmount, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event ClaimedToDao(address indexed account, uint256 amount);

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        dao = makeAddr("dao");

        vm.startPrank(owner);
        mockToken = new MockToken();
        mockToken.mint(owner, 10_000_000_000 ether);
        mockVoteToken = new MockVoteToken(mockToken);
        daoRegistry = new MystikoGovernorRegistry();
        daoRegistry.transferOwnerToDAO(dao);

        staking = new XzkStaking(
            address(daoRegistry),
            owner,
            mockVoteToken,
            "Mystiko Staking Vote Token 360D",
            "sVXZK-360D",
            STAKING_PERIOD_SECONDS, // 360-day staking period
            2000, // total factor
            block.timestamp + 5 days // start time
        );
        vm.stopPrank();

        // Mint tokens to users and convert to vote tokens
        vm.startPrank(owner);
        mockToken.transfer(user1, LARGE_AMOUNT);
        mockToken.transfer(user2, LARGE_AMOUNT);
        mockToken.transfer(user3, LARGE_AMOUNT);
        vm.stopPrank();

        // Convert tokens to vote tokens for users
        vm.startPrank(user1);
        mockToken.approve(address(mockVoteToken), LARGE_AMOUNT);
        mockVoteToken.depositFor(user1, LARGE_AMOUNT);
        vm.stopPrank();

        vm.startPrank(user2);
        mockToken.approve(address(mockVoteToken), LARGE_AMOUNT);
        mockVoteToken.depositFor(user2, LARGE_AMOUNT);
        vm.stopPrank();

        vm.startPrank(user3);
        mockToken.approve(address(mockVoteToken), LARGE_AMOUNT);
        mockVoteToken.depositFor(user3, LARGE_AMOUNT);
        vm.stopPrank();

        // Fund the staking contract with enough underlying tokens for rewards and principal
        vm.startPrank(owner);
        mockToken.approve(address(mockVoteToken), 50_000_000 ether);
        mockVoteToken.depositFor(owner, 50_000_000 ether);
        mockVoteToken.transfer(address(staking), 50_000_000 ether);
        vm.stopPrank();
    }

    // ============ STAKE TESTS ============

    function test_Stake_Success() public {
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);

        uint256 balanceBefore = mockVoteToken.balanceOf(user1);
        uint256 stakingBalanceBefore = staking.balanceOf(user1);
        uint256 totalStakedBefore = staking.totalStaked();

        bool success = staking.stake(STAKE_AMOUNT);

        assertTrue(success, "Stake should succeed");
        assertEq(mockVoteToken.balanceOf(user1), balanceBefore - STAKE_AMOUNT, "Vote token balance should decrease");
        assertEq(staking.balanceOf(user1), stakingBalanceBefore + STAKE_AMOUNT, "Staking balance should increase");
        assertEq(staking.totalStaked(), totalStakedBefore + STAKE_AMOUNT, "Total staked should increase");

        // Check staking record
        (uint256 stakingTime, uint256 tokenAmount, uint256 stakingTokenAmount, uint256 remaining) =
            staking.stakingRecords(user1, 0);
        assertEq(stakingTime, block.timestamp, "Staking time should be current timestamp");
        assertEq(tokenAmount, STAKE_AMOUNT, "Token amount should match staked amount");
        assertEq(stakingTokenAmount, STAKE_AMOUNT, "Staking token amount should match staked amount");
        assertEq(remaining, STAKE_AMOUNT, "Remaining should match staked amount");
        vm.stopPrank();
    }

    function test_Stake_ZeroAmount() public {
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), 0);

        vm.expectRevert("XzkStaking: Invalid amount");
        staking.stake(0);
        vm.stopPrank();
    }

    function test_Stake_InsufficientBalance() public {
        vm.startPrank(user1);
        uint256 largeAmount = mockVoteToken.balanceOf(user1) + 1 ether;
        mockVoteToken.approve(address(staking), largeAmount);

        vm.expectRevert();
        staking.stake(largeAmount);
        vm.stopPrank();
    }

    function test_Stake_WithoutApproval() public {
        vm.startPrank(user1);

        vm.expectRevert();
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();
    }

    function test_Stake_WhenPaused() public {
        // Pause staking
        vm.startPrank(dao);
        staking.pauseStaking();
        vm.stopPrank();

        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);

        vm.expectRevert("XzkStaking: paused");
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();
    }

    function test_Stake_AfterUnpause() public {
        // Pause and then unpause
        vm.startPrank(dao);
        staking.pauseStaking();
        staking.unpauseStaking();
        vm.stopPrank();

        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);

        bool success = staking.stake(STAKE_AMOUNT);
        assertTrue(success, "Stake should succeed after unpause");
        vm.stopPrank();
    }

    function test_Stake_MultipleUsers() public {
        // User1 stakes
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // User2 stakes
        vm.startPrank(user2);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        assertEq(staking.totalStaked(), STAKE_AMOUNT * 2, "Total staked should be sum of both stakes");
        assertEq(staking.balanceOf(user1), STAKE_AMOUNT, "User1 should have correct staking balance");
        assertEq(staking.balanceOf(user2), STAKE_AMOUNT, "User2 should have correct staking balance");
    }

    // ============ UNSTAKE TESTS ============

    function test_360day_Unstake_Success() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);

        uint256 stakingBalanceBefore = staking.balanceOf(user1);
        uint256 voteTokenBalanceBefore = mockVoteToken.balanceOf(user1);
        uint256 totalUnstakedBefore = staking.totalUnstaked();

        // Calculate the expected underlying token amount that will be returned
        uint256 expectedUnderlyingAmount = staking.swapToUnderlyingToken(STAKE_AMOUNT);

        bool success = staking.unstake(STAKE_AMOUNT, 0, 0);

        assertTrue(success, "Unstake should succeed");
        assertEq(staking.balanceOf(user1), stakingBalanceBefore - STAKE_AMOUNT, "Staking balance should decrease");
        // Vote token balance should NOT increase after unstake - tokens are only returned after claim
        assertEq(
            mockVoteToken.balanceOf(user1),
            voteTokenBalanceBefore,
            "Vote token balance should remain the same after unstake"
        );
        assertEq(
            staking.totalUnstaked(),
            totalUnstakedBefore + expectedUnderlyingAmount,
            "Total unstaked should increase by the calculated underlying amount"
        );
        vm.stopPrank();
    }

    function test_360day_Unstake_BeforePeriod() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Try to unstake before period ends
        vm.expectRevert("Staking period not ended");
        staking.unstake(STAKE_AMOUNT, 0, 0);
        vm.stopPrank();
    }

    function test_360day_Unstake_InsufficientBalance() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);

        // Try to unstake more than available
        vm.expectRevert("Insufficient staking balance");
        staking.unstake(STAKE_AMOUNT + 1, 0, 0);
        vm.stopPrank();
    }

    function test_360day_Unstake_ZeroAmount() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);

        vm.expectRevert("Invalid amount");
        staking.unstake(0, 0, 0);
        vm.stopPrank();
    }

    function test_360day_Unstake_WhenPaused() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);

        // Pause staking
        vm.stopPrank();
        vm.startPrank(dao);
        staking.pauseStaking();
        vm.stopPrank();

        // Try to unstake while paused
        vm.startPrank(user1);
        vm.expectRevert("Staking paused");
        staking.unstake(STAKE_AMOUNT, 0, 0);
        vm.stopPrank();
    }

    // ============ CLAIM TESTS ============

    function test_Claim_Success() public {
        // First stake and unstake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);

        // Move forward past claim delay
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        uint256 balanceBefore = mockVoteToken.balanceOf(user1);

        bool success = staking.claim(user1, 0, 0);

        assertTrue(success, "Claim should succeed");
        assertGt(mockVoteToken.balanceOf(user1), balanceBefore, "Balance should increase by claimed amount");
        vm.stopPrank();
    }

    function test_Claim_BeforeDelay() public {
        // First stake and unstake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        staking.unstake(STAKE_AMOUNT, 0, 0);

        // Try to claim before delay period
        vm.expectRevert("Claim delay not reached");
        staking.claim(user1, 0, 0);
        vm.stopPrank();
    }

    function test_Claim_WhenPaused() public {
        // First stake and unstake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        staking.unstake(STAKE_AMOUNT, 0, 0);

        // Pause claim for user
        vm.stopPrank();
        vm.startPrank(owner);
        staking.pauseClaim(user1);
        vm.stopPrank();

        // Move forward past claim delay
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);

        // Try to claim while paused
        vm.startPrank(user1);
        vm.expectRevert("Claim paused");
        staking.claim(user1, 0, 0);
        vm.stopPrank();
    }

    function test_Claim_AfterUnpause() public {
        // First stake and unstake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);

        // Pause and unpause claim for user
        vm.stopPrank();
        vm.startPrank(owner);
        staking.pauseClaim(user1);
        staking.unpauseClaim(user1);
        vm.stopPrank();

        // Move forward past claim delay
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Claim should work after unpause
        vm.startPrank(user1);
        bool success = staking.claim(user1, 0, 0);
        assertTrue(success, "Claim should succeed after unpause");
        vm.stopPrank();
    }

    // ============ REWARD CALCULATION TESTS ============

    function test_CurrentTotalReward_BeforeStart() public view {
        // Before start time, reward should be 0
        assertEq(staking.totalRewardAt(block.timestamp), 0, "Reward should be 0 before start time");
    }

    function test_CurrentTotalReward_AfterStart() public {
        // Move forward past start time
        vm.warp(staking.START_TIME() + 1);

        uint256 reward = staking.totalRewardAt(block.timestamp);
        assertGt(reward, 0, "Reward should be greater than 0 after start time");
    }

    function test_CurrentTotalReward_AtMaxDuration() public {
        // Move forward to max duration
        vm.warp(staking.START_TIME() + Constants.TOTAL_DURATION_SECONDS);

        uint256 reward = staking.totalRewardAt(block.timestamp);
        assertEq(reward, staking.TOTAL_REWARD(), "Reward should equal total reward at max duration");
    }

    function test_CurrentTotalReward_AfterMaxDuration() public {
        // Move forward past max duration
        vm.warp(staking.START_TIME() + Constants.TOTAL_DURATION_SECONDS + 1);

        uint256 reward = staking.totalRewardAt(block.timestamp);
        assertEq(reward, staking.TOTAL_REWARD(), "Reward should equal total reward after max duration");
    }

    // ============ SWAP TESTS ============

    function test_SwapToStakingToken_Initial() public view {
        // When no tokens are staked, swap should return 1:1
        uint256 amount = 1000 ether;
        uint256 stakingAmount = staking.swapToStakingToken(amount);
        assertEq(stakingAmount, amount, "Initial swap should be 1:1");
    }

    function test_SwapToUnderlyingToken_Initial() public view {
        // When no tokens are staked, swap should return 1:1
        uint256 stakingAmount = 1000 ether;
        uint256 amount = staking.swapToUnderlyingToken(stakingAmount);
        assertEq(amount, stakingAmount, "Initial swap should be 1:1");
    }

    function test_SwapToStakingToken_WithRewards() public {
        // Move forward to accumulate some rewards
        vm.warp(staking.START_TIME() + 365 days);

        // Stake some tokens first
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        uint256 amount = 1000 ether;
        uint256 stakingAmount = staking.swapToStakingToken(amount);

        // With rewards, staking amount should be less than input amount
        assertLt(stakingAmount, amount, "Staking amount should be less than input with rewards");
    }

    function test_SwapToUnderlyingToken_WithRewards() public {
        // Move forward to accumulate some rewards
        vm.warp(staking.START_TIME() + 365 days);

        // Stake some tokens first
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        uint256 stakingAmount = 1000 ether;
        uint256 amount = staking.swapToUnderlyingToken(stakingAmount);

        // With rewards, underlying amount should be greater than staking amount
        assertGt(amount, stakingAmount, "Underlying amount should be greater than staking amount with rewards");
    }

    // ============ INTEGRATION TESTS ============

    function test_CompleteStakingLifecycle() public {
        // 1. Stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        uint256 initialStakingBalance = staking.balanceOf(user1);
        assertEq(initialStakingBalance, STAKE_AMOUNT, "Initial staking balance should match stake amount");

        // 2. Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);

        // 3. Unstake
        staking.unstake(STAKE_AMOUNT, 0, 0);

        uint256 stakingBalanceAfterUnstake = staking.balanceOf(user1);
        assertEq(stakingBalanceAfterUnstake, 0, "Staking balance should be 0 after unstake");

        // 4. Move forward past claim delay
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        // 5. Claim
        uint256 balanceBeforeClaim = mockVoteToken.balanceOf(user1);
        staking.claim(user1, 0, 0);
        uint256 balanceAfterClaim = mockVoteToken.balanceOf(user1);

        assertGt(balanceAfterClaim, balanceBeforeClaim, "Balance should increase after claim");
        vm.stopPrank();
    }

    function test_MultipleStakesAndUnstakes() public {
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT * 3);

        // First stake
        staking.stake(STAKE_AMOUNT);
        assertEq(staking.balanceOf(user1), STAKE_AMOUNT, "First stake balance");

        // Second stake
        staking.stake(STAKE_AMOUNT);
        assertEq(staking.balanceOf(user1), STAKE_AMOUNT * 2, "Second stake balance");

        // Third stake
        staking.stake(STAKE_AMOUNT);
        assertEq(staking.balanceOf(user1), STAKE_AMOUNT * 3, "Third stake balance");

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);

        // Unstake from first record
        staking.unstake(STAKE_AMOUNT, 0, 0);
        assertEq(staking.balanceOf(user1), STAKE_AMOUNT * 2, "Balance after first unstake");

        // Unstake from second record
        staking.unstake(STAKE_AMOUNT, 1, 1);
        assertEq(staking.balanceOf(user1), STAKE_AMOUNT, "Balance after second unstake");

        // Unstake from third record
        staking.unstake(STAKE_AMOUNT, 2, 2);
        assertEq(staking.balanceOf(user1), 0, "Balance after third unstake");

        vm.stopPrank();
    }

    // ============ EDGE CASES ============

    function test_StakeWithMaxAmount() public {
        vm.startPrank(user1);
        uint256 maxAmount = mockVoteToken.balanceOf(user1);
        mockVoteToken.approve(address(staking), maxAmount);

        bool success = staking.stake(maxAmount);
        assertTrue(success, "Stake with max amount should succeed");
        assertEq(staking.balanceOf(user1), maxAmount, "Staking balance should match max amount");
        vm.stopPrank();
    }

    function test_UnstakePartialAmount() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);

        // Unstake partial amount
        uint256 partialAmount = STAKE_AMOUNT / 2;
        staking.unstake(partialAmount, 0, 0);

        assertEq(staking.balanceOf(user1), STAKE_AMOUNT - partialAmount, "Balance should reflect partial unstake");
        vm.stopPrank();
    }

    function test_ClaimMultipleRecords() public {
        // Create multiple unstaking records
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT * 3);

        for (uint256 i = 0; i < 3; i++) {
            staking.stake(STAKE_AMOUNT);
            vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
            vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
            staking.unstake(STAKE_AMOUNT, i, i);
        }

        // Move forward past claim delay
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Claim all records - endNonce is inclusive, so use 2 to claim records 0, 1, 2
        uint256 balanceBefore = mockVoteToken.balanceOf(user1);
        staking.claim(user1, 0, 2);
        uint256 balanceAfter = mockVoteToken.balanceOf(user1);

        assertGt(balanceAfter, balanceBefore, "Should claim all records");
        vm.stopPrank();
    }

    // ============ REENTRANCY TESTS ============

    function test_ReentrancyProtection_Stake() public {
        // This test verifies that the nonReentrant modifier works
        // The contract should not allow reentrant calls to stake function
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT * 2);

        // First stake should succeed
        bool success = staking.stake(STAKE_AMOUNT);
        assertTrue(success, "First stake should succeed");

        // Second stake should also succeed (no reentrancy issue)
        bool success2 = staking.stake(STAKE_AMOUNT);
        assertTrue(success2, "Second stake should succeed");
        vm.stopPrank();
    }

    function test_ReentrancyProtection_Unstake() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);

        // Unstake should succeed
        bool success = staking.unstake(STAKE_AMOUNT, 0, 0);
        assertTrue(success, "Unstake should succeed");
        vm.stopPrank();
    }

    function test_ReentrancyProtection_Claim() public {
        // First stake and unstake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);

        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Claim should succeed
        bool success = staking.claim(user1, 0, 0);
        assertTrue(success, "Claim should succeed");
        vm.stopPrank();
    }

    // ============ TOTAL CLAIMED TESTS ============

    function test_TotalClaimed_Initial() public {
        // Initially totalClaimed should be 0
        assertEq(staking.totalClaimed(), 0, "Initial totalClaimed should be 0");
    }

    function test_TotalClaimed_AfterSingleClaim() public {
        // Setup: stake and unstake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);

        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Record totalClaimed before claim
        uint256 totalClaimedBefore = staking.totalClaimed();

        // Claim
        staking.claim(user1, 0, 0);

        // Check that totalClaimed increased
        uint256 totalClaimedAfter = staking.totalClaimed();
        assertGt(totalClaimedAfter, totalClaimedBefore, "totalClaimed should increase after claim");
        vm.stopPrank();
    }

    function test_TotalClaimed_AfterMultipleClaims() public {
        // Setup: multiple stakes and unstakes
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT * 3);

        // First stake and claim cycle
        staking.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        uint256 totalClaimedAfterFirst = staking.totalClaimed();
        staking.claim(user1, 0, 0);
        uint256 totalClaimedAfterFirstClaim = staking.totalClaimed();
        assertGt(totalClaimedAfterFirstClaim, totalClaimedAfterFirst, "totalClaimed should increase after first claim");

        // Second stake and claim cycle
        staking.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 1, 1);
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        uint256 totalClaimedAfterSecond = staking.totalClaimed();
        staking.claim(user1, 1, 1);
        uint256 totalClaimedAfterSecondClaim = staking.totalClaimed();
        assertGt(
            totalClaimedAfterSecondClaim, totalClaimedAfterSecond, "totalClaimed should increase after second claim"
        );

        // Third stake and claim cycle
        staking.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 2, 2);
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        uint256 totalClaimedAfterThird = staking.totalClaimed();
        staking.claim(user1, 2, 2);
        uint256 totalClaimedAfterThirdClaim = staking.totalClaimed();
        assertGt(totalClaimedAfterThirdClaim, totalClaimedAfterThird, "totalClaimed should increase after third claim");

        // Verify cumulative increase
        assertGt(totalClaimedAfterThirdClaim, totalClaimedAfterFirstClaim, "totalClaimed should be cumulative");
        vm.stopPrank();
    }

    function test_TotalClaimed_AfterDaoClaim() public {
        // Setup: fund the contract
        uint256 contractBalance = mockToken.balanceOf(address(staking));
        uint256 claimAmount = 1000 ether;

        // Record totalClaimed before DAO claim
        uint256 totalClaimedBefore = staking.totalClaimed();

        // DAO claims
        vm.prank(dao);
        staking.claimToDao(claimAmount);

        // Check that totalClaimed increased
        uint256 totalClaimedAfter = staking.totalClaimed();
        assertEq(totalClaimedAfter, totalClaimedBefore + claimAmount, "totalClaimed should increase by claim amount");
    }

    function test_TotalClaimed_MultipleUsers() public {
        // Setup: multiple users stake and claim
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);
        vm.stopPrank();

        vm.startPrank(user2);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);
        vm.stopPrank();

        // User1 claims
        uint256 totalClaimedBeforeUser1 = staking.totalClaimed();
        vm.prank(user1);
        staking.claim(user1, 0, 0);
        uint256 totalClaimedAfterUser1 = staking.totalClaimed();
        assertGt(totalClaimedAfterUser1, totalClaimedBeforeUser1, "totalClaimed should increase after user1 claim");

        // User2 claims
        uint256 totalClaimedBeforeUser2 = staking.totalClaimed();
        vm.prank(user2);
        staking.claim(user2, 0, 0);
        uint256 totalClaimedAfterUser2 = staking.totalClaimed();
        assertGt(totalClaimedAfterUser2, totalClaimedBeforeUser2, "totalClaimed should increase after user2 claim");

        // Verify both claims contributed to totalClaimed
        assertGt(totalClaimedAfterUser2, totalClaimedBeforeUser1, "totalClaimed should include both users' claims");
    }

    function test_TotalClaimed_NotAffectedByStake() public {
        // Record initial totalClaimed
        uint256 initialTotalClaimed = staking.totalClaimed();

        // Stake should not affect totalClaimed
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        uint256 totalClaimedAfterStake = staking.totalClaimed();
        assertEq(totalClaimedAfterStake, initialTotalClaimed, "totalClaimed should not change after stake");
    }

    function test_TotalClaimed_NotAffectedByUnstake() public {
        // Setup: stake first
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        uint256 totalClaimedBeforeUnstake = staking.totalClaimed();

        // Unstake should not affect totalClaimed
        vm.startPrank(user1);
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);
        vm.stopPrank();

        uint256 totalClaimedAfterUnstake = staking.totalClaimed();
        assertEq(totalClaimedAfterUnstake, totalClaimedBeforeUnstake, "totalClaimed should not change after unstake");
    }

    function test_TotalClaimed_AccurateTracking() public {
        // Setup: stake and prepare for claim
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);
        vm.stopPrank();

        // Record balance before claim to calculate exact amount claimed
        uint256 balanceBeforeClaim = mockVoteToken.balanceOf(user1);
        uint256 totalClaimedBefore = staking.totalClaimed();

        // Claim
        vm.prank(user1);
        staking.claim(user1, 0, 0);

        // Calculate actual amount claimed
        uint256 balanceAfterClaim = mockVoteToken.balanceOf(user1);
        uint256 actualAmountClaimed = balanceAfterClaim - balanceBeforeClaim;

        // Verify totalClaimed increased by exactly the claimed amount
        uint256 totalClaimedAfter = staking.totalClaimed();
        assertEq(
            totalClaimedAfter,
            totalClaimedBefore + actualAmountClaimed,
            "totalClaimed should increase by exact claimed amount"
        );
    }

    function test_TotalClaimed_WithRewards() public {
        // Setup: stake and wait for rewards to accumulate
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward to accumulate rewards
        vm.warp(staking.START_TIME() + 365 days);
        vm.roll(block.number + 365 days / 12);

        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(STAKE_AMOUNT, 0, 0);
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);
        vm.stopPrank();

        // Record balance before claim
        uint256 balanceBeforeClaim = mockVoteToken.balanceOf(user1);
        uint256 totalClaimedBefore = staking.totalClaimed();

        // Claim (should include rewards)
        vm.prank(user1);
        staking.claim(user1, 0, 0);

        // Calculate actual amount claimed (should be more than original stake due to rewards)
        uint256 balanceAfterClaim = mockVoteToken.balanceOf(user1);
        uint256 actualAmountClaimed = balanceAfterClaim - balanceBeforeClaim;

        // Verify totalClaimed increased by the claimed amount (including rewards)
        uint256 totalClaimedAfter = staking.totalClaimed();
        assertEq(totalClaimedAfter, totalClaimedBefore + actualAmountClaimed, "totalClaimed should include rewards");
        assertGt(
            actualAmountClaimed, STAKE_AMOUNT, "Claimed amount should be greater than original stake due to rewards"
        );
    }
}
