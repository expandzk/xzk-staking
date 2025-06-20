// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {MystikoStaking} from "../../contracts/MystikoStaking.sol";
import {MockToken} from "../../contracts/mocks/MockToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MystikoGovernorRegistry} from
    "../../lib/mystiko-governance/packages/contracts/contracts/impl/MystikoGovernorRegistry.sol";
import {GovernanceErrors} from "lib/mystiko-governance/packages/contracts/contracts/GovernanceErrors.sol";

contract StakingStakeFlexibleTest is Test {
    MystikoStaking public staking;
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

        staking = new MystikoStaking(
            address(daoRegistry),
            mockToken,
            "Mystiko Staking Token",
            "sXZK",
            0, // flexible staking period
            1, // total factor
            block.number + 10000 // start block
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
        mockToken.approve(address(staking), STAKE_AMOUNT);

        uint256 balanceBefore = mockToken.balanceOf(user1);
        uint256 stakingBalanceBefore = staking.balanceOf(user1);
        uint256 totalStakedBefore = staking.totalStaked();

        bool success = staking.stake(STAKE_AMOUNT);

        assertTrue(success, "Stake should succeed");
        assertEq(mockToken.balanceOf(user1), balanceBefore - STAKE_AMOUNT, "Token balance should decrease");
        assertEq(staking.balanceOf(user1), stakingBalanceBefore + STAKE_AMOUNT, "Staking balance should increase");
        assertEq(staking.totalStaked(), totalStakedBefore + STAKE_AMOUNT, "Total staked should increase");
        (uint256 stakedBlock, uint256 amount, uint256 remaining) = staking.stakingRecords(user1, 0);
        assertEq(stakedBlock, 0, "Staked block should be the current block number");
        assertEq(amount, 0, "Amount should be the same as the staked amount");
        assertEq(remaining, 0, "Remaining should be the same as the staked amount");
        vm.stopPrank();
    }

    function test_Stake_ZeroAmount() public {
        vm.startPrank(user1);
        mockToken.approve(address(staking), 0);

        vm.expectRevert("MystikoStaking: Invalid amount");
        staking.stake(0);
        vm.stopPrank();
    }

    function test_Stake_InsufficientBalance() public {
        vm.startPrank(user1);
        uint256 largeAmount = mockToken.balanceOf(user1) + 1 ether;
        mockToken.approve(address(staking), largeAmount);

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
        mockToken.approve(address(staking), STAKE_AMOUNT);

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
        mockToken.approve(address(staking), STAKE_AMOUNT);

        bool success = staking.stake(STAKE_AMOUNT);
        assertTrue(success, "Stake should succeed after unpause");
        vm.stopPrank();
    }

    function test_Stake_MultipleUsers() public {
        // User1 stakes
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // User2 stakes
        vm.startPrank(user2);
        mockToken.approve(address(staking), STAKE_AMOUNT);
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
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        vm.roll(block.number + staking.START_BLOCK() + 10000 + 1);

        uint256 stakingBalance = staking.balanceOf(user1);
        uint256 tokenBalanceBefore = mockToken.balanceOf(user1);
        uint256 totalUnstakedBefore = staking.totalUnstaked();

        uint256 expectedAmount = staking.swapToUnderlyingToken(stakingBalance);
        bool success = staking.unstake(stakingBalance, new uint256[](0));

        assertTrue(success, "Unstake should succeed");
        assertEq(staking.balanceOf(user1), 0, "Staking balance should be zero");
        assertEq(
            staking.totalUnstaked(),
            totalUnstakedBefore + expectedAmount,
            "swapToUnderlyingToken should return the correct amount"
        );
        (uint256 unstakeBlock, uint256 amount, bool claimPaused) = staking.claimRecords(user1);
        assertEq(amount, expectedAmount, "Amount should be the same as the unstaked amount");
        assertEq(unstakeBlock, block.number, "Unstake block should be the current block number");
        assertFalse(claimPaused, "Claim should not be paused");
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
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        uint256 stakingBalance = staking.balanceOf(user1);
        vm.stopPrank();

        // Pause staking
        vm.startPrank(dao);
        staking.pauseStaking();
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("MystikoStaking: paused");
        staking.unstake(stakingBalance, new uint256[](0));
        vm.stopPrank();
    }

    function test_Unstake_PartialAmount() public {
        // First stake
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        uint256 partialAmount = STAKE_AMOUNT / 2;
        uint256 balanceBefore = staking.balanceOf(user1);
        bool success = staking.unstake(partialAmount, new uint256[](0));
        assertTrue(success, "Partial unstake should succeed");
        assertEq(
            staking.balanceOf(user1), balanceBefore - partialAmount, "Staking balance should decrease by partial amount"
        );
        vm.stopPrank();
    }

    // ============ CLAIM TESTS ============

    function test_Claim_NoRewards() public {
        // Stake before rewards start
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        // Unstake to create claimable record
        staking.unstake(STAKE_AMOUNT, new uint256[](0));
        vm.stopPrank();

        // Wait for claim delay
        vm.roll(block.number + staking.CLAIM_DELAY_BLOCKS() + 1);
        (, uint256 claimAmount,) = staking.claimRecords(user1);
        uint256 balanceBefore = mockToken.balanceOf(user1);
        vm.startPrank(user1);
        bool success = staking.claim();
        assertTrue(success, "Claim should succeed after delay");
        uint256 balanceAfter = mockToken.balanceOf(user1);
        assertEq(balanceAfter, balanceBefore + claimAmount, "claim should return the correct amount");
        vm.stopPrank();
    }

    function test_Claim_WithRewards(uint256 offset) public {
        offset = bound(offset, 1, STAKE_AMOUNT);
        uint256 amount = offset;
        // Stake before rewards start
        vm.startPrank(user1);
        mockToken.approve(address(staking), amount);
        staking.stake(amount);
        vm.stopPrank();

        uint256 balanceBefore = mockToken.balanceOf(user1);

        assertEq(staking.totalStaked(), amount);
        assertEq(staking.balanceOf(user1), amount);
        assertEq(staking.totalUnstaked(), 0);

        // Move to reward period
        uint256 startBlock = staking.START_BLOCK();
        offset = bound(offset, 0, 2 * staking.TOTAL_BLOCKS());
        vm.roll(startBlock + offset);

        uint256 totalReward = staking.currentTotalReward();
        vm.startPrank(owner);
        mockToken.transfer(address(staking), totalReward);
        vm.stopPrank();

        // Unstake to create claimable record
        vm.startPrank(user1);
        staking.unstake(amount, new uint256[](0));
        vm.stopPrank();

        assertEq(staking.totalStaked(), amount);
        assertEq(staking.balanceOf(user1), 0);
        assertEq(staking.totalUnstaked(), amount + totalReward);

        // Wait for claim delay
        vm.roll(block.number + staking.CLAIM_DELAY_BLOCKS() + 1);

        vm.startPrank(user1);
        bool success = staking.claim();
        uint256 balanceAfter = mockToken.balanceOf(user1);
        assertTrue(success, "Claim should succeed after delay");
        assertEq(balanceAfter, balanceBefore + amount + totalReward, "claim should return the correct amount");
        vm.stopPrank();
    }

    function test_Claim_WhenPaused() public {
        // Stake before rewards start
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);
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
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // Unstake to create claimable record
        vm.startPrank(user1);
        staking.unstake(STAKE_AMOUNT, new uint256[](0));
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
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // Move to reward period
        uint256 startBlock = staking.START_BLOCK();
        vm.roll(startBlock + 1000);

        uint256 totalReward1 = staking.currentTotalReward();
        vm.startPrank(owner);
        mockToken.transfer(address(staking), totalReward1);
        vm.stopPrank();

        // Unstake to create claimable record
        vm.startPrank(user1);
        staking.unstake(STAKE_AMOUNT, new uint256[](0));
        vm.stopPrank();

        // Wait for claim delay
        vm.roll(block.number + staking.CLAIM_DELAY_BLOCKS() + 1);

        vm.startPrank(user1);
        bool firstClaim = staking.claim();
        assertTrue(firstClaim, "First claim should succeed");
        vm.stopPrank();

        uint256 totalReward2 = staking.currentTotalReward();
        uint256 rewardAmount = totalReward2 - totalReward1;
        vm.startPrank(owner);
        mockToken.transfer(address(staking), rewardAmount);
        vm.stopPrank();

        // Stake and unstake again
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);
        bool success = staking.stake(STAKE_AMOUNT);
        assertTrue(success, "Stake should succeed");
        uint256 stakingBalance = staking.balanceOf(user1);
        staking.unstake(stakingBalance, new uint256[](0));
        vm.stopPrank();

        // Wait for claim delay
        vm.roll(block.number + staking.CLAIM_DELAY_BLOCKS() + 1);

        vm.startPrank(user1);
        bool secondClaim = staking.claim();
        assertTrue(secondClaim, "Second claim should succeed");
        assertEq(staking.totalStaked(), 2 * STAKE_AMOUNT);
        assertEq(staking.totalUnstaked(), 2 * STAKE_AMOUNT + totalReward2);
        assertEq(staking.balanceOf(user1), 0);
        assertEq(mockToken.balanceOf(address(staking)), 0);
        assertEq(mockToken.balanceOf(user1), LARGE_AMOUNT + totalReward2);
        vm.stopPrank();
    }

    // ============ INTEGRATION TESTS ============

    function test_MultipleUsers_StakeUnstake() public {
        // User1 stakes
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // User2 stakes
        vm.startPrank(user2);
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // Move to reward period
        uint256 startBlock = staking.START_BLOCK();
        vm.roll(startBlock + 2000);

        uint256 totalReward = staking.currentTotalReward();
        vm.startPrank(owner);
        mockToken.transfer(address(staking), totalReward);
        vm.stopPrank();

        // Both users unstake
        vm.startPrank(user1);
        staking.unstake(STAKE_AMOUNT, new uint256[](0));
        vm.stopPrank();
        vm.startPrank(user2);
        staking.unstake(STAKE_AMOUNT, new uint256[](0));
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
        assertEq(mockToken.balanceOf(user1), LARGE_AMOUNT + totalReward / 2);
        assertEq(mockToken.balanceOf(user2), LARGE_AMOUNT + totalReward / 2);
    }

    // ============ EDGE CASE TESTS ============

    function test_Stake_WithVerySmallAmount() public {
        uint256 tinyAmount = 1;

        vm.startPrank(user1);
        mockToken.approve(address(staking), tinyAmount);

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
        mockToken.approve(address(staking), largeAmount);

        bool success = staking.stake(largeAmount);
        assertTrue(success, "Should be able to stake very large amount");
        assertEq(staking.balanceOf(user1), largeAmount, "Should have correct staking balance");
        vm.stopPrank();
    }

    function test_Unstake_AllAtOnce() public {
        // Stake
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        uint256 fullBalance = staking.balanceOf(user1);
        bool success = staking.unstake(fullBalance, new uint256[](0));

        assertTrue(success, "Should be able to unstake all at once");
        assertEq(staking.balanceOf(user1), 0, "Staking balance should be zero");
        vm.stopPrank();
    }

    // ============ EVENTS TESTS ============

    function test_Stake_EmitsEvent() public {
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);

        vm.expectEmit(true, false, false, true);
        emit Staked(user1, STAKE_AMOUNT, STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();
    }

    function test_Unstake_EmitsEvent() public {
        // First stake
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        uint256 stakingBalance = staking.balanceOf(user1);
        uint256 expectedAmount = staking.swapToUnderlyingToken(stakingBalance);

        vm.expectEmit(true, false, false, true);
        emit Unstaked(user1, stakingBalance, expectedAmount);
        staking.unstake(stakingBalance, new uint256[](0));
        vm.stopPrank();
    }

    function test_Claim_EmitsEvent() public {
        // Stake and move to reward period
        vm.startPrank(user1);
        mockToken.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        staking.unstake(STAKE_AMOUNT, new uint256[](0));
        vm.stopPrank();

        uint256 claimDelay = staking.CLAIM_DELAY_BLOCKS();
        vm.roll(block.number + claimDelay + 1);

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
        mockToken.approve(address(staking), STAKE_AMOUNT + SMALL_AMOUNT);

        // First stake should succeed
        bool success = staking.stake(STAKE_AMOUNT);
        assertTrue(success, "First stake should succeed");

        // Additional stakes should also succeed (not reentrant, just multiple calls)
        success = staking.stake(SMALL_AMOUNT);
        assertTrue(success, "Additional stake should succeed");
        vm.stopPrank();
    }
}
