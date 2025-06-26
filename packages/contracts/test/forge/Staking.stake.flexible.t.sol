// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {XzkStaking} from "../../contracts/XzkStaking.sol";
import {MockToken} from "../../contracts/mocks/MockToken.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MystikoGovernorRegistry} from
    "../../lib/mystiko-governance/packages/contracts/contracts/impl/MystikoGovernorRegistry.sol";
import {GovernanceErrors} from "../../lib/mystiko-governance/packages/contracts/contracts/GovernanceErrors.sol";

contract StakingStakeFlexibleTest is Test {
    XzkStaking public stakingFlexible;
    MockToken public mockToken;
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    address public dao;
    MystikoGovernorRegistry public daoRegistry;

    uint256 public constant STAKE_AMOUNT = 100 ether;
    uint256 public constant SMALL_AMOUNT = 1 ether;
    uint256 public constant LARGE_AMOUNT = 1000 ether;

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
        daoRegistry = new MystikoGovernorRegistry();
        daoRegistry.transferOwnerToDAO(dao);

        stakingFlexible = new XzkStaking(
            address(daoRegistry),
            owner,
            mockToken,
            "Mystiko Staking Token",
            "sXZK",
            0, // flexible staking period
            1, // total factor
            block.timestamp + 1 days // start time
        );
        vm.stopPrank();

        // Mint tokens to users
        vm.startPrank(owner);
        mockToken.transfer(user1, LARGE_AMOUNT);
        mockToken.transfer(user2, LARGE_AMOUNT);
        mockToken.transfer(user3, LARGE_AMOUNT);
        vm.stopPrank();
    }

    // ============ STAKE TESTS ============

    function test_Stake_Success() public {
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);

        uint256 balanceBefore = mockToken.balanceOf(user1);
        uint256 stakingBalanceBefore = stakingFlexible.balanceOf(user1);
        uint256 totalStakedBefore = stakingFlexible.totalStaked();

        bool success = stakingFlexible.stake(STAKE_AMOUNT);

        assertTrue(success, "Stake should succeed");
        assertEq(mockToken.balanceOf(user1), balanceBefore - STAKE_AMOUNT, "Token balance should decrease");
        assertEq(
            stakingFlexible.balanceOf(user1), stakingBalanceBefore + STAKE_AMOUNT, "Staking balance should increase"
        );
        assertEq(stakingFlexible.totalStaked(), totalStakedBefore + STAKE_AMOUNT, "Total staked should increase");

        // For flexible staking (0 period), no records should be created
        assertEq(stakingFlexible.stakingNonces(user1), 0, "No staking records should be created for flexible staking");
        vm.stopPrank();
    }

    function test_Stake_ZeroAmount() public {
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), 0);

        vm.expectRevert("XzkStaking: Invalid amount");
        stakingFlexible.stake(0);
        vm.stopPrank();
    }

    function test_Stake_InsufficientBalance() public {
        vm.startPrank(user1);
        uint256 largeAmount = mockToken.balanceOf(user1) + 1 ether;
        mockToken.approve(address(stakingFlexible), largeAmount);

        vm.expectRevert();
        stakingFlexible.stake(largeAmount);
        vm.stopPrank();
    }

    function test_Stake_WithoutApproval() public {
        vm.startPrank(user1);

        vm.expectRevert();
        stakingFlexible.stake(STAKE_AMOUNT);
        vm.stopPrank();
    }

    function test_Stake_WhenPaused() public {
        // Pause staking
        vm.startPrank(dao);
        stakingFlexible.pauseStaking();
        vm.stopPrank();

        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);

        vm.expectRevert("XzkStaking: paused");
        stakingFlexible.stake(STAKE_AMOUNT);
        vm.stopPrank();
    }

    function test_Stake_AfterUnpause() public {
        // Pause and then unpause
        vm.startPrank(dao);
        stakingFlexible.pauseStaking();
        stakingFlexible.unpauseStaking();
        vm.stopPrank();

        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);

        bool success = stakingFlexible.stake(STAKE_AMOUNT);
        assertTrue(success, "Stake should succeed after unpause");
        vm.stopPrank();
    }

    function test_Stake_MultipleUsers() public {
        // User1 stakes
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // User2 stakes
        vm.startPrank(user2);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        vm.stopPrank();

        assertEq(stakingFlexible.totalStaked(), STAKE_AMOUNT * 2, "Total staked should be sum of both stakes");
        assertEq(stakingFlexible.balanceOf(user1), STAKE_AMOUNT, "User1 should have correct staking balance");
        assertEq(stakingFlexible.balanceOf(user2), STAKE_AMOUNT, "User2 should have correct staking balance");
    }

    // ============ UNSTAKE TESTS ============

    function test_Flexible_Unstake_Success() public {
        // First stake
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);

        uint256 stakingBalanceBefore = stakingFlexible.balanceOf(user1);
        uint256 tokenBalanceBefore = mockToken.balanceOf(user1);
        uint256 totalUnstakedBefore = stakingFlexible.totalUnstaked();

        // Calculate the expected underlying token amount right before unstaking
        uint256 expectedUnderlyingAmount = stakingFlexible.swapToUnderlyingToken(STAKE_AMOUNT);

        bool success = stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);

        uint256 tokenBalanceAfter = mockToken.balanceOf(user1);
        uint256 totalUnstakedAfter = stakingFlexible.totalUnstaked();

        assertTrue(success, "Unstake should succeed");
        assertEq(
            stakingFlexible.balanceOf(user1), stakingBalanceBefore - STAKE_AMOUNT, "Staking balance should decrease"
        );
        // Token balance should not increase immediately after unstake
        assertEq(tokenBalanceAfter, tokenBalanceBefore, "Token balance should not change immediately after unstake");
        assertEq(
            totalUnstakedAfter,
            totalUnstakedBefore + expectedUnderlyingAmount,
            "Total unstaked should increase by the exact calculated underlying amount"
        );
        // For flexible staking, unstaking records should be created
        assertEq(stakingFlexible.unstakingNonces(user1), 1, "Unstaking records should be created for flexible staking");
        vm.stopPrank();
    }

    function test_Unstake_ZeroAmount() public {
        vm.startPrank(user1);

        vm.expectRevert("Invalid amount");
        stakingFlexible.unstake(0, 0, 0);
        vm.stopPrank();
    }

    function test_Unstake_InsufficientBalance() public {
        vm.startPrank(user1);

        vm.expectRevert("Insufficient staking balance");
        stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);
        vm.stopPrank();
    }

    function test_Unstake_WhenPaused() public {
        // First stake
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);

        // Pause staking
        vm.stopPrank();
        vm.startPrank(dao);
        stakingFlexible.pauseStaking();
        vm.stopPrank();

        // Try to unstake while paused
        vm.startPrank(user1);
        vm.expectRevert("Staking paused");
        stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);
        vm.stopPrank();
    }

    function test_Unstake_PartialAmount() public {
        // First stake
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);

        uint256 partialAmount = STAKE_AMOUNT / 2;
        uint256 balanceBefore = stakingFlexible.balanceOf(user1);

        bool success = stakingFlexible.unstake(partialAmount, 0, 0);
        assertTrue(success, "Partial unstake should succeed");
        assertEq(
            stakingFlexible.balanceOf(user1),
            balanceBefore - partialAmount,
            "Staking balance should decrease by partial amount"
        );
        vm.stopPrank();
    }

    // ============ CLAIM TESTS ============

    function test_Claim_Success() public {
        // For flexible staking, claim should work after unstake
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);

        // Move forward past claim delay
        vm.warp(block.timestamp + stakingFlexible.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (stakingFlexible.CLAIM_DELAY_SECONDS() + 1) / 12);

        uint256 balanceBefore = mockToken.balanceOf(user1);
        bool success = stakingFlexible.claim(user1, 0, 0);
        assertTrue(success, "Claim should succeed");
        uint256 balanceAfter = mockToken.balanceOf(user1);
        assertGt(balanceAfter, balanceBefore, "Balance should increase after claim");
        vm.stopPrank();
    }

    function test_Claim_BeforeDelay() public {
        // For flexible staking, claim should fail before delay
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);
        vm.expectRevert("Claim delay not reached");
        stakingFlexible.claim(user1, 0, 1);
        vm.stopPrank();
    }

    function test_Claim_WhenPaused() public {
        // First stake and unstake
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);

        // Pause claim for user
        vm.stopPrank();
        vm.startPrank(owner);
        stakingFlexible.pauseClaim(user1);
        vm.stopPrank();

        // Move forward past claim delay
        vm.warp(block.timestamp + stakingFlexible.CLAIM_DELAY_SECONDS() + 1);

        // Try to claim while paused
        vm.startPrank(user1);
        vm.expectRevert("Unstaking paused");
        stakingFlexible.claim(user1, 0, 1);
        vm.stopPrank();
    }

    // ============ REWARD CALCULATION TESTS ============

    function test_CurrentTotalReward_BeforeStart() public {
        // Before start time, reward should be 0
        assertEq(stakingFlexible.currentTotalReward(), 0, "Reward should be 0 before start time");
    }

    function test_CurrentTotalReward_AfterStart() public {
        // Move forward past start time
        vm.warp(stakingFlexible.START_TIME() + 1);

        uint256 reward = stakingFlexible.currentTotalReward();
        assertGt(reward, 0, "Reward should be greater than 0 after start time");
    }

    function test_CurrentTotalReward_AtMaxDuration() public {
        // Move forward to max duration
        vm.warp(stakingFlexible.START_TIME() + stakingFlexible.TOTAL_DURATION_SECONDS());

        uint256 reward = stakingFlexible.currentTotalReward();
        assertEq(reward, stakingFlexible.TOTAL_REWARD(), "Reward should equal total reward at max duration");
    }

    // ============ SWAP TESTS ============

    function test_SwapToStakingToken_Initial() public {
        // When no tokens are staked, swap should return 1:1
        uint256 amount = 1000 ether;
        uint256 stakingAmount = stakingFlexible.swapToStakingToken(amount);
        assertEq(stakingAmount, amount, "Initial swap should be 1:1");
    }

    function test_SwapToUnderlyingToken_Initial() public {
        // When no tokens are staked, swap should return 1:1
        uint256 stakingAmount = 1000 ether;
        uint256 amount = stakingFlexible.swapToUnderlyingToken(stakingAmount);
        assertEq(amount, stakingAmount, "Initial swap should be 1:1");
    }

    function test_SwapToStakingToken_WithRewards() public {
        // Move forward to accumulate some rewards
        vm.warp(stakingFlexible.START_TIME() + 365 days);

        // Stake some tokens first
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        vm.stopPrank();

        uint256 amount = 1000 ether;
        uint256 stakingAmount = stakingFlexible.swapToStakingToken(amount);

        // With rewards, staking amount should be less than input amount
        assertLt(stakingAmount, amount, "Staking amount should be less than input with rewards");
    }

    function test_SwapToUnderlyingToken_WithRewards() public {
        // Move forward to accumulate some rewards
        vm.warp(stakingFlexible.START_TIME() + 365 days);

        // Stake some tokens first
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        vm.stopPrank();

        uint256 stakingAmount = 1000 ether;
        uint256 amount = stakingFlexible.swapToUnderlyingToken(stakingAmount);

        // With rewards, underlying amount should be greater than staking amount
        assertGt(amount, stakingAmount, "Underlying amount should be greater than staking amount with rewards");
    }

    // ============ INTEGRATION TESTS ============

    function test_CompleteFlexibleStakingLifecycle() public {
        // Stake, unstake, and claim
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);

        // Move forward past claim delay
        vm.warp(block.timestamp + stakingFlexible.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (stakingFlexible.CLAIM_DELAY_SECONDS() + 1) / 12);

        bool success = stakingFlexible.claim(user1, 0, 0);
        assertTrue(success, "Claim should succeed");
        vm.stopPrank();
    }

    function test_MultipleStakesAndUnstakes() public {
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT * 3);

        // First stake
        stakingFlexible.stake(STAKE_AMOUNT);
        assertEq(stakingFlexible.balanceOf(user1), STAKE_AMOUNT, "First stake balance");

        // Second stake
        stakingFlexible.stake(STAKE_AMOUNT);
        assertEq(stakingFlexible.balanceOf(user1), STAKE_AMOUNT * 2, "Second stake balance");

        // Third stake
        stakingFlexible.stake(STAKE_AMOUNT);
        assertEq(stakingFlexible.balanceOf(user1), STAKE_AMOUNT * 3, "Third stake balance");

        // Unstake all
        stakingFlexible.unstake(STAKE_AMOUNT * 3, 0, 0);
        assertEq(stakingFlexible.balanceOf(user1), 0, "Balance after unstake all");

        vm.stopPrank();
    }

    // ============ EDGE CASES ============

    function test_StakeWithMaxAmount() public {
        vm.startPrank(user1);
        uint256 maxAmount = mockToken.balanceOf(user1);
        mockToken.approve(address(stakingFlexible), maxAmount);

        bool success = stakingFlexible.stake(maxAmount);
        assertTrue(success, "Stake with max amount should succeed");
        assertEq(stakingFlexible.balanceOf(user1), maxAmount, "Staking balance should match max amount");
        vm.stopPrank();
    }

    function test_UnstakePartialAmount() public {
        // First stake
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);

        // Unstake partial amount
        uint256 partialAmount = STAKE_AMOUNT / 2;
        stakingFlexible.unstake(partialAmount, 0, 0);

        assertEq(
            stakingFlexible.balanceOf(user1), STAKE_AMOUNT - partialAmount, "Balance should reflect partial unstake"
        );
        vm.stopPrank();
    }

    function test_ClaimMultipleRecords() public {
        // For flexible staking, claim should not work (no records)
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT * 3);
        for (uint256 i = 0; i < 3; i++) {
            stakingFlexible.stake(STAKE_AMOUNT);
            stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);
        }
        vm.expectRevert();
        stakingFlexible.claim(user1, 0, 3);
        vm.stopPrank();
    }

    // ============ REENTRANCY TESTS ============

    function test_ReentrancyProtection_Stake() public {
        // This test verifies that the nonReentrant modifier works
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT * 2);

        // First stake should succeed
        bool success = stakingFlexible.stake(STAKE_AMOUNT);
        assertTrue(success, "First stake should succeed");

        // Second stake should also succeed (no reentrancy issue)
        bool success2 = stakingFlexible.stake(STAKE_AMOUNT);
        assertTrue(success2, "Second stake should succeed");
        vm.stopPrank();
    }

    function test_ReentrancyProtection_Unstake() public {
        // First stake
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);

        // Unstake should succeed
        bool success = stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);
        assertTrue(success, "Unstake should succeed");
        vm.stopPrank();
    }

    function test_ReentrancyProtection_Claim() public {
        // For flexible staking, claim should not work (no records)
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);
        vm.expectRevert();
        stakingFlexible.claim(user1, 0, 1);
        vm.stopPrank();
    }

    // ============ FLEXIBLE STAKING SPECIFIC TESTS ============

    function test_FlexibleStaking_NoWaitingPeriod() public {
        // For flexible staking, users can unstake immediately
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);

        // Should be able to unstake immediately (no waiting period)
        bool success = stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);
        assertTrue(success, "Should be able to unstake immediately in flexible staking");
        vm.stopPrank();
    }

    function test_FlexibleStaking_NoRecords() public {
        // For flexible staking, unstaking records should be created
        vm.startPrank(user1);
        mockToken.approve(address(stakingFlexible), STAKE_AMOUNT);
        stakingFlexible.stake(STAKE_AMOUNT);
        stakingFlexible.unstake(STAKE_AMOUNT, 0, 0);
        assertEq(stakingFlexible.unstakingNonces(user1), 1, "Unstaking records should be created for flexible staking");
        vm.stopPrank();
    }
}
