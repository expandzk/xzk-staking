// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {XzkStaking} from "../../contracts/XzkStaking.sol";
import {MockToken} from "../../contracts/mocks/MockToken.sol";
import {MockVoteToken} from "../../contracts/mocks/MockVoteToken.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MystikoGovernorRegistry} from
    "../../lib/mystiko-governance/packages/contracts/contracts/impl/MystikoGovernorRegistry.sol";
import {GovernanceErrors} from "../../lib/mystiko-governance/packages/contracts/contracts/GovernanceErrors.sol";

contract StakingStakeIntegrationTest is Test {
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
    uint256 public constant LARGE_AMOUNT = 1000 ether;
    uint256 public constant STAKING_PERIOD_SECONDS = 90 days;

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
        mockVoteToken = new MockVoteToken(mockToken);
        daoRegistry = new MystikoGovernorRegistry();
        daoRegistry.transferOwnerToDAO(dao);

        staking = new XzkStaking(
            address(daoRegistry),
            owner,
            mockVoteToken,
            "Mystiko Staking Vote Token 90D",
            "sVXZK-90D",
            STAKING_PERIOD_SECONDS,
            1500, // total factor
            block.timestamp + 1 days // start time
        );
        vm.stopPrank();

        // Transfer tokens to users and convert to vote tokens
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

        vm.startPrank(owner);
        uint256 ownerBalance = mockToken.balanceOf(owner);
        mockToken.approve(address(mockVoteToken), ownerBalance);
        mockVoteToken.depositFor(owner, ownerBalance);
        vm.stopPrank();
    }

    function test_Stake_multiple_users_multiple_stakes(uint256 seed) public {
        vm.warp(staking.START_TIME() + 1);

        uint256 user1Nonce = 0;
        uint256 user2Nonce = 0;
        uint256 user3Nonce = 0;
        uint256 totalRewardsTransferred = 0;

        for (uint256 i = 0; i < 60; i++) {
            // Generate random values
            uint256 randomSeed = bound(seed, 1, type(uint256).max);
            uint256 userChoice = uint256(keccak256(abi.encodePacked(randomSeed, i, "user"))) % 3;
            uint256 operationChoice = uint256(keccak256(abi.encodePacked(randomSeed, i, "op"))) % 3;
            uint256 timeInterval =
                bound(uint256(keccak256(abi.encodePacked(randomSeed, i, "time"))), 12 hours, 24 hours);
            uint256 amount = bound(uint256(keccak256(abi.encodePacked(randomSeed, i, "amount"))), 1 ether, 100 ether);

            address currentUser;
            if (userChoice == 0) {
                currentUser = user1;
            } else if (userChoice == 1) {
                currentUser = user2;
            } else {
                currentUser = user3;
            }

            // Move forward by random time
            vm.warp(block.timestamp + timeInterval);

            vm.startPrank(owner);
            uint256 totalRewards = staking.totalRewardAt(block.timestamp);
            uint256 ownerBalance = mockVoteToken.balanceOf(owner);
            uint256 availableRewards = totalRewards - totalRewardsTransferred;
            uint256 transferAmount = availableRewards > ownerBalance ? ownerBalance : availableRewards;
            if (transferAmount > 0) {
                mockVoteToken.transfer(address(staking), transferAmount);
                totalRewardsTransferred += transferAmount;
            }
            vm.stopPrank();

            vm.startPrank(currentUser);

            if (operationChoice == 0) {
                // Stake operation
                uint256 userBalance = mockVoteToken.balanceOf(currentUser);
                uint256 stakeAmount = amount > userBalance ? userBalance : amount;
                if (stakeAmount > 0) {
                    mockVoteToken.approve(address(staking), stakeAmount);
                    bool success = staking.stake(stakeAmount);
                    assertTrue(success, "Stake should succeed");
                    if (userChoice == 0) {
                        user1Nonce++;
                        assertEq(user1Nonce, staking.stakingNonces(user1));
                    } else if (userChoice == 1) {
                        user2Nonce++;
                        assertEq(user2Nonce, staking.stakingNonces(user2));
                    } else {
                        user3Nonce++;
                        assertEq(user3Nonce, staking.stakingNonces(user3));
                    }
                }
            } else if (operationChoice == 1) {
                // Unstake operation
                uint256 userStakingBalance = staking.balanceOf(currentUser);
                if (userStakingBalance > 0) {
                    // Check if staking period has ended
                    uint256 unstakeNonce = 0;
                    uint256 unstakeAmount = 0;
                    (unstakeNonce, unstakeAmount) =
                        findUnstakeNonce(currentUser, staking.stakingNonces(currentUser), randomSeed);

                    if (unstakeAmount > 0) {
                        vm.startPrank(currentUser);
                        bool success = staking.unstake(unstakeAmount, unstakeNonce, unstakeNonce);
                        assertTrue(success, "Unstake should succeed");
                        vm.stopPrank();
                    }
                }
            } else {
                // Claim operation
                uint256 unstakingNonce = staking.unstakingNonces(currentUser);
                if (unstakingNonce > 0) {
                    // Check if claim delay has passed for any record
                    bool canClaim = false;
                    for (uint256 j = 0; j < unstakingNonce; j++) {
                        (uint256 unstakingTime,,,,) = staking.unstakingRecords(currentUser, j);
                        if (block.timestamp > unstakingTime + staking.CLAIM_DELAY_SECONDS()) {
                            canClaim = true;
                            break;
                        }
                    }

                    if (canClaim) {
                        // endNonce is inclusive, so use unstakingNonce - 1 to claim all existing records
                        bool success = staking.claim(currentUser, 0, unstakingNonce - 1);
                        assertTrue(success, "Claim should succeed");
                    }
                }
            }
            vm.stopPrank();
        }

        uint256 user1Balance = mockVoteToken.balanceOf(user1);
        uint256 user2Balance = mockVoteToken.balanceOf(user2);
        uint256 user3Balance = mockVoteToken.balanceOf(user3);
        uint256 stakingBalance = mockVoteToken.balanceOf(address(staking));
        assertEq(
            user1Balance + user2Balance + user3Balance + stakingBalance, LARGE_AMOUNT * 3 + totalRewardsTransferred
        );
    }

    function findUnstakeNonce(address user, uint256 currentNonce, uint256 randomSeed)
        public
        view
        returns (uint256, uint256)
    {
        uint256 start = bound(randomSeed, 0, currentNonce - 1);
        uint256 unstakeNonce = 0;
        bool found = false;
        for (uint256 j = start; j < currentNonce; j++) {
            (uint256 stakingTime,,, uint256 remaining) = staking.stakingRecords(user, j);
            if (remaining > 0 && block.timestamp > stakingTime + staking.STAKING_PERIOD_SECONDS()) {
                unstakeNonce = j;
                found = true;
                break;
            }
        }

        if (!found) {
            // Try from beginning
            for (uint256 j = 0; j < currentNonce; j++) {
                (uint256 stakingTime,,, uint256 remaining) = staking.stakingRecords(user, j);
                if (remaining > 0 && block.timestamp > stakingTime + staking.STAKING_PERIOD_SECONDS()) {
                    unstakeNonce = j;
                    found = true;
                    break;
                }
            }
        }

        if (found) {
            (,,, uint256 remaining) = staking.stakingRecords(user, unstakeNonce);
            return (unstakeNonce, remaining);
        }

        return (0, 0);
    }

    function test_CompleteLifecycle() public {
        // Test complete staking lifecycle for a single user
        vm.warp(staking.START_TIME() + 1);
        vm.roll(10);

        vm.startPrank(user1);
        mockVoteToken.approve(address(staking), STAKE_AMOUNT);

        // 1. Stake
        bool success = staking.stake(STAKE_AMOUNT);
        assertTrue(success, "Stake should succeed");
        assertEq(staking.balanceOf(user1), STAKE_AMOUNT, "Staking balance should match stake amount");

        // 2. Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(10);

        // 3. Unstake
        success = staking.unstake(STAKE_AMOUNT, 0, 0);
        assertTrue(success, "Unstake should succeed");
        assertEq(staking.balanceOf(user1), 0, "Staking balance should be 0 after unstake");

        // 4. Move forward past claim delay
        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(10);
        vm.stopPrank();

        vm.startPrank(owner);
        uint256 totalRewards = staking.totalRewardAt(block.timestamp);
        mockVoteToken.transfer(address(staking), totalRewards);
        vm.stopPrank();

        vm.startPrank(user1);
        // 5. Claim
        uint256 balanceBefore = mockVoteToken.balanceOf(user1);
        success = staking.claim(user1, 0, 0);
        assertTrue(success, "Claim should succeed");
        uint256 balanceAfter = mockVoteToken.balanceOf(user1);
        assertGt(balanceAfter, balanceBefore, "Balance should increase after claim");
        vm.stopPrank();
    }
}
