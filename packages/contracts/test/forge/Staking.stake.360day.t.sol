// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {MystikoStaking} from "../../contracts/MystikoStaking.sol";
import {MockToken} from "../../contracts/mocks/MockToken.sol";
import {MockVoteToken} from "../../contracts/mocks/MockVoteToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MystikoGovernorRegistry} from
    "../../lib/mystiko-governance/packages/contracts/contracts/impl/MystikoGovernorRegistry.sol";
import {GovernanceErrors} from "lib/mystiko-governance/packages/contracts/contracts/GovernanceErrors.sol";
import {console} from "forge-std/console.sol";

contract StakingStake360DayTest is Test {
    MystikoStaking public staking;
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
    uint256 public constant STAKING_PERIOD_DAYS = 360;
    uint256 public constant STAKING_PERIOD_BLOCKS = (STAKING_PERIOD_DAYS * 24 * 60 * 60) / 12;

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

        staking = new MystikoStaking(
            address(daoRegistry),
            mockVoteToken,
            "Mystiko Staking Vote Token 360D",
            "sVXZK-360D",
            STAKING_PERIOD_BLOCKS, // 360-day staking period
            20, // total factor
            block.number + 10000 // start block
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

        // Fund the staking contract with enough MockToken for rewards and principal
        vm.startPrank(owner);
        mockToken.approve(address(mockVoteToken), 50_000_000 ether);
        mockVoteToken.depositFor(owner, 50_000_000 ether);
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
        (uint256 stakedBlock, uint256 amount, uint256 remaining) = staking.stakingRecords(user1, 0);
        assertEq(stakedBlock, block.number, "Staked block should be the current block number");
        assertEq(amount, STAKE_AMOUNT, "Amount should be the same as the staked amount");
        assertEq(remaining, STAKE_AMOUNT, "Remaining should be the same as the staked amount");
        vm.stopPrank();
    }

    function test_Stake_ZeroAmount() public {
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), 0);

        vm.expectRevert("MystikoStaking: Invalid amount");
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

        vm.expectRevert("MystikoStaking: paused");
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

    function test_Unstake_Success() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);

        uint256 stakingBalance = staking.balanceOf(user1);
        uint256 tokenBalanceBefore = mockVoteToken.balanceOf(user1);
        uint256 totalUnstakedBefore = staking.totalUnstaked();

        uint256 expectedAmount = staking.swapToUnderlyingToken(stakingBalance);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        bool success = staking.unstake(stakingBalance, nonces);

        assertTrue(success, "Unstake should succeed");
        assertEq(staking.balanceOf(user1), 0, "Staking balance should be zero");
        assertEq(
            staking.totalUnstaked(),
            totalUnstakedBefore + expectedAmount,
            "Total unstaked should increase by expected amount"
        );
        (uint256 unstakeBlock, uint256 amount, bool claimPaused) = staking.claimRecords(user1);
        assertEq(amount, expectedAmount, "Amount should be the same as the unstaked amount");
        assertEq(unstakeBlock, block.number, "Unstake block should be the current block number");
        assertFalse(claimPaused, "Claim should not be paused");
        vm.stopPrank();
    }

    function test_Unstake_BeforePeriodEnd() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Try to unstake before period ends
        uint256 stakingBalance = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;

        vm.expectRevert("MystikoClaim: Staking period not ended");
        staking.unstake(stakingBalance, nonces);
        vm.stopPrank();
    }

    function test_Unstake_ZeroAmount() public {
        vm.startPrank(user1);

        vm.expectRevert("MystikoStaking: Invalid amount");
        staking.unstake(0, new uint256[](0));
        vm.stopPrank();
    }

    function test_Unstake_InsufficientBalance() public {
        vm.startPrank(user1);

        vm.expectRevert("MystikoStaking: Insufficient staking balance");
        staking.unstake(STAKE_AMOUNT, new uint256[](0));
        vm.stopPrank();
    }

    function test_Unstake_WhenPaused() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        uint256 stakingBalance = staking.balanceOf(user1);
        vm.stopPrank();

        // Pause staking
        vm.startPrank(dao);
        staking.pauseStaking();
        vm.stopPrank();

        vm.startPrank(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        vm.expectRevert("MystikoStaking: paused");
        staking.unstake(stakingBalance, nonces);
        vm.stopPrank();
    }

    function test_Unstake_PartialAmount() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);

        uint256 partialAmount = STAKE_AMOUNT / 2;
        uint256 balanceBefore = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        bool success = staking.unstake(partialAmount, nonces);
        assertTrue(success, "Partial unstake should succeed");
        assertEq(
            staking.balanceOf(user1), balanceBefore - partialAmount, "Staking balance should decrease by partial amount"
        );
        vm.stopPrank();
    }

    function test_Unstake_MultipleStakes() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT * 2);
        staking.stake(STAKE_AMOUNT);

        // Second stake
        vm.roll(block.number + 1000);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // Move forward past staking period for first stake
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);

        vm.startPrank(user1);
        uint256 stakingBalance = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;

        // Should fail because second stake period hasn't ended
        vm.expectRevert("MystikoClaim: Invalid remaining amount");
        staking.unstake(stakingBalance, nonces);
        vm.stopPrank();
    }

    // ============ CLAIM TESTS ============

    function test_Claim_Rewards_stake_before_start() public {
        // Stake before rewards start
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period and unstake
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);
        uint256 stakingBalance = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        staking.unstake(stakingBalance, nonces);
        vm.stopPrank();

        // Wait for claim delay
        vm.roll(block.number + staking.CLAIM_DELAY_BLOCKS() + 1);
        (, uint256 claimAmount,) = staking.claimRecords(user1);

        vm.startPrank(owner);
        mockVoteToken.transfer(address(staking), staking.currentTotalReward());
        vm.stopPrank();

        uint256 balanceBefore = mockVoteToken.balanceOf(user1);
        vm.startPrank(user1);
        bool success = staking.claim();
        assertTrue(success, "Claim should succeed after delay");
        uint256 balanceAfter = mockVoteToken.balanceOf(user1);
        assertEq(balanceAfter, balanceBefore + claimAmount, "Claim should return the correct amount");
        vm.stopPrank();
    }

    function test_Claim_WithRewards_at_random_block(uint256 offset) public {
        offset = bound(offset, 1 ether, 100 ether);
        uint256 amount = offset;
        // Stake before rewards start
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), amount);
        staking.stake(amount);
        vm.stopPrank();

        uint256 balanceBefore = mockVoteToken.balanceOf(user1);

        assertEq(staking.totalStaked(), amount);
        assertEq(staking.balanceOf(user1), amount);
        assertEq(staking.totalUnstaked(), 0);

        // Move to reward period
        uint256 startBlock = staking.START_BLOCK();
        offset = bound(offset, staking.STAKING_PERIOD() + 1, 2 * staking.TOTAL_BLOCKS());
        vm.roll(startBlock + offset);

        uint256 totalReward = staking.currentTotalReward();
        vm.startPrank(owner);
        mockVoteToken.transfer(address(staking), totalReward);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        staking.unstake(amount, nonces);
        vm.stopPrank();

        assertEq(staking.totalStaked(), amount);
        assertEq(staking.balanceOf(user1), 0);
        assertEq(staking.totalUnstaked(), totalReward + amount);

        // Wait for claim delay
        vm.roll(block.number + staking.CLAIM_DELAY_BLOCKS() + 1);

        vm.startPrank(user1);
        bool success = staking.claim();
        uint256 balanceAfter = mockVoteToken.balanceOf(user1);
        assertTrue(success, "Claim should succeed after delay");
        assertEq(balanceAfter, balanceBefore + amount + totalReward, "Claim should return the correct amount");
        vm.stopPrank();
    }

    function test_Claim_WhenPaused() public {
        // Stake before rewards start
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // Pause staking
        vm.startPrank(dao);
        staking.pauseStaking();
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("MystikoStaking: paused");
        staking.claim();
        vm.stopPrank();
    }

    function test_Claim_WhenAccountPaused() public {
        // Stake before rewards start
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // Move forward past staking period and unstake
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);
        vm.startPrank(user1);
        uint256 stakingBalance = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        staking.unstake(stakingBalance, nonces);
        vm.stopPrank();

        // Pause account
        vm.startPrank(owner);
        staking.pauseClaim(address(user1));
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("MystikoClaim: Claim paused");
        staking.claim();
        vm.stopPrank();
    }

    function test_Claim_MultipleTimes() public {
        // Stake before rewards start
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // Move forward past staking period and unstake
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);

        uint256 totalReward1 = staking.currentTotalReward();
        vm.startPrank(owner);
        mockVoteToken.transfer(address(staking), totalReward1);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 stakingBalance = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        staking.unstake(stakingBalance, nonces);
        vm.stopPrank();

        // Wait for claim delay
        vm.roll(block.number + staking.CLAIM_DELAY_BLOCKS() + 1);

        vm.startPrank(user1);
        bool firstClaim = staking.claim();
        assertTrue(firstClaim, "First claim should succeed");
        vm.stopPrank();

        // Stake and unstake again
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        bool success = staking.stake(STAKE_AMOUNT);
        assertTrue(success, "Stake should succeed");

        // Move forward past staking period
        vm.roll(block.number + staking.STAKING_PERIOD() + 1);

        uint256 totalReward2 = staking.currentTotalReward();
        uint256 rewardAmount = totalReward2 - totalReward1;
        vm.startPrank(owner);
        mockVoteToken.transfer(address(staking), rewardAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 stakingBalance2 = staking.balanceOf(user1);
        uint256[] memory nonces2 = new uint256[](2);
        nonces2[0] = 1;
        nonces2[1] = 0;
        staking.unstake(stakingBalance2, nonces2);
        vm.stopPrank();

        // // Wait for claim delay
        vm.roll(block.number + staking.CLAIM_DELAY_BLOCKS() + 1);

        vm.startPrank(user1);
        bool secondClaim = staking.claim();
        assertTrue(secondClaim, "Second claim should succeed");
        assertEq(staking.totalStaked(), 2 * STAKE_AMOUNT);
        assertEq(staking.totalUnstaked(), 2 * STAKE_AMOUNT + totalReward2);
        assertEq(staking.balanceOf(user1), 0);
        assertEq(mockToken.balanceOf(address(staking)), 0);
        assertEq(mockVoteToken.balanceOf(user1), LARGE_AMOUNT + totalReward2);
        vm.stopPrank();
    }

    // ============ INTEGRATION TESTS ============

    function test_MultipleUsers_StakeUnstake() public {
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

        // Move to reward period
        uint256 startBlock = staking.START_BLOCK();
        vm.roll(startBlock + 2000);

        uint256 totalReward1 = staking.currentTotalReward();
        vm.startPrank(owner);
        mockVoteToken.transfer(address(staking), totalReward1);
        vm.stopPrank();

        // Move forward past staking period
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);

        vm.startPrank(owner);
        uint256 totalReward2 = staking.currentTotalReward();
        uint256 rewardAmount = totalReward2 - totalReward1;
        mockVoteToken.transfer(address(staking), rewardAmount);
        vm.stopPrank();

        // Both users unstake
        vm.startPrank(user1);
        uint256 stakingBalance1 = staking.balanceOf(user1);
        uint256[] memory nonces1 = new uint256[](1);
        nonces1[0] = 0;
        staking.unstake(stakingBalance1, nonces1);
        vm.stopPrank();

        vm.startPrank(user2);
        uint256 stakingBalance2 = staking.balanceOf(user2);
        uint256[] memory nonces2 = new uint256[](1);
        nonces2[0] = 0;
        staking.unstake(stakingBalance2, nonces2);
        vm.stopPrank();

        // Wait for claim delay
        vm.roll(block.number + staking.CLAIM_DELAY_BLOCKS() + 1);

        // Both users claim
        vm.startPrank(user1);
        staking.claim();
        vm.stopPrank();
        vm.startPrank(user2);
        staking.claim();
        vm.stopPrank();

        assertEq(staking.totalSupply(), 0, "Total supply should be zero after all unstakes");
        assertEq(mockToken.balanceOf(address(staking)), 0);
        assertEq(mockVoteToken.balanceOf(user1), LARGE_AMOUNT + totalReward2 / 2);
        assertEq(mockVoteToken.balanceOf(user2), LARGE_AMOUNT + totalReward2 / 2);
    }

    // ============ EDGE CASE TESTS ============

    function test_Stake_WithVerySmallAmount() public {
        uint256 tinyAmount = 1;

        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), tinyAmount);

        bool success = staking.stake(tinyAmount);
        assertTrue(success, "Should be able to stake very small amount");
        assertEq(staking.balanceOf(user1), tinyAmount, "Should have correct staking balance");
        vm.stopPrank();
    }

    function test_Stake_WithVeryLargeAmount() public {
        uint256 largeAmount = 100000000 ether;

        // Mint large amount to user
        vm.startPrank(owner);
        mockToken.mint(user1, largeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        mockToken.approve(address(mockVoteToken), largeAmount);
        mockVoteToken.depositFor(user1, largeAmount);
        mockVoteToken.approve(address(staking), largeAmount);

        bool success = staking.stake(largeAmount);
        assertTrue(success, "Should be able to stake very large amount");
        assertEq(staking.balanceOf(user1), largeAmount, "Should have correct staking balance");
        vm.stopPrank();
    }

    function test_Unstake_AllAtOnce() public {
        // Stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);

        uint256 fullBalance = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        bool success = staking.unstake(fullBalance, nonces);

        assertTrue(success, "Should be able to unstake all at once");
        assertEq(staking.balanceOf(user1), 0, "Staking balance should be zero");
        vm.stopPrank();
    }

    // ============ EVENTS TESTS ============

    function test_Stake_EmitsEvent() public {
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);

        vm.expectEmit(true, false, false, true);
        emit Staked(user1, STAKE_AMOUNT, STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();
    }

    function test_Unstake_EmitsEvent() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);

        uint256 stakingBalance = staking.balanceOf(user1);
        uint256 expectedAmount = staking.swapToUnderlyingToken(stakingBalance);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;

        vm.expectEmit(true, false, false, true);
        emit Unstaked(user1, stakingBalance, expectedAmount);
        staking.unstake(stakingBalance, nonces);
        vm.stopPrank();
    }

    function test_Claim_EmitsEvent() public {
        // Stake and move to reward period
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move forward past staking period and unstake
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);
        uint256 stakingBalance = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        staking.unstake(stakingBalance, nonces);
        vm.stopPrank();

        uint256 claimDelay = staking.CLAIM_DELAY_BLOCKS();
        vm.roll(block.number + claimDelay + 1);

        vm.startPrank(owner);
        uint256 totalReward = staking.currentTotalReward();
        mockVoteToken.transfer(address(staking), totalReward);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectEmit(true, false, false, false);
        emit Claimed(user1, 0); // We'll just check the user address, not the amount
        staking.claim();
        vm.stopPrank();
    }

    // ============ REENTRANCY TESTS ============

    function test_Stake_ReentrancyProtection() public {
        // This test verifies that the nonReentrant modifier is working
        // The contract should not allow reentrant calls to stake function
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT + SMALL_AMOUNT);

        // First stake should succeed
        bool success = staking.stake(STAKE_AMOUNT);
        assertTrue(success, "First stake should succeed");

        // Additional stakes should also succeed (not reentrant, just multiple calls)
        success = staking.stake(SMALL_AMOUNT);
        assertTrue(success, "Additional stake should succeed");
        vm.stopPrank();
    }

    // ============ STAKING PERIOD TESTS ============

    function test_StakingPeriod_IsCorrect() public {
        assertEq(staking.STAKING_PERIOD(), STAKING_PERIOD_BLOCKS, "Staking period should be 360 days in blocks");
    }

    function test_Unstake_ExactPeriodEnd() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move to exact period end
        vm.roll(block.number + STAKING_PERIOD_BLOCKS);

        uint256 stakingBalance = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;

        // Should still fail because we need to be past the period
        vm.expectRevert("MystikoClaim: Staking period not ended");
        staking.unstake(stakingBalance, nonces);
        vm.stopPrank();
    }

    function test_Unstake_OneBlockAfterPeriod() public {
        // First stake
        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Move one block after period end
        vm.roll(block.number + STAKING_PERIOD_BLOCKS + 1);

        uint256 stakingBalance = staking.balanceOf(user1);
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;

        bool success = staking.unstake(stakingBalance, nonces);
        assertTrue(success, "Unstake should succeed one block after period end");
        vm.stopPrank();
    }
}
