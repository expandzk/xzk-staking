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

contract StakingStakeIntegrationTest is Test {
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
    uint256 public constant LARGE_AMOUNT = 10000 ether;
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
        mockToken.mint(owner, 10_000_000_000 ether);
        mockVoteToken = new MockVoteToken(mockToken);
        daoRegistry = new MystikoGovernorRegistry();
        daoRegistry.transferOwnerToDAO(dao);

        staking = new MystikoStaking(
            address(daoRegistry),
            owner,
            mockVoteToken,
            "Mystiko Staking Vote Token 90D",
            "sVXZK-90D",
            STAKING_PERIOD_SECONDS,
            15, // total factor
            block.timestamp + 1 days // start time
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

    function test_Stake_multiple_users_multiple_stakes(uint256 seed) public {
        vm.warp(staking.START_TIME() + 1);
        vm.roll(block.number + staking.START_DELAY_SECONDS() / 12);

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
            vm.roll(block.number + (timeInterval / 12));

            vm.startPrank(owner);
            uint256 totalRewards = staking.currentTotalReward();
            mockVoteToken.transfer(address(staking), totalRewards - totalRewardsTransferred);
            totalRewardsTransferred = totalRewards;
            vm.stopPrank();

            vm.startPrank(currentUser);

            if (operationChoice == 0) {
                // Stake operation
                uint256 userBalance = mockVoteToken.balanceOf(currentUser);
                mockVoteToken.approve(address(staking), amount);
                bool success = staking.stake(amount);
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
            } else if (operationChoice == 1) {
                // Unstake operation
                uint256 stakingBalance = staking.balanceOf(currentUser);
                if (stakingBalance > 0) {
                    // Check if staking period has ended
                    uint256 unstakeNonce = 0;
                    uint256 unstakeAmount = 0;
                    (unstakeNonce, unstakeAmount) =
                        findUnstakeNonce(currentUser, staking.stakingNonces(currentUser), randomSeed);

                    if (unstakeAmount > 0) {
                        // Calculate expected unstaked amount and fund contract
                        uint256 expectedAmount = staking.swapToUnderlyingToken(unstakeAmount);

                        uint256[] memory nonces = new uint256[](1);
                        nonces[0] = unstakeNonce;

                        vm.startPrank(currentUser);
                        bool success = staking.unstake(unstakeAmount, nonces);
                        assertTrue(success, "Unstake should succeed");
                    }
                }
            } else {
                // Claim operation
                (, uint256 claimAmount,) = staking.claimRecords(currentUser);
                if (claimAmount > 0) {
                    // Check if claim delay has passed
                    (, uint256 unstakeTimestamp,) = staking.claimRecords(currentUser);
                    if (block.timestamp > unstakeTimestamp + staking.CLAIM_DELAY_SECONDS()) {
                        bool success = staking.claim();
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
            (uint256 stakedBlock,, uint256 remaining) = staking.stakingRecords(user, j);
            if (remaining > 0 && block.timestamp > stakedBlock + staking.STAKING_PERIOD_SECONDS()) {
                return (j, remaining);
            }
        }

        for (uint256 j = 0; j < start; j++) {
            (uint256 stakedBlock,, uint256 remaining) = staking.stakingRecords(user, j);
            if (remaining > 0 && block.timestamp > stakedBlock + staking.STAKING_PERIOD_SECONDS()) {
                return (j, remaining);
            }
        }
        return (0, 0);
    }
}
