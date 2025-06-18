// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MystikoStakingRecord} from "../../contracts/MystikoStakingRecord.sol";

contract MockMystikoStakingRecord is MystikoStakingRecord {
    constructor(uint256 _stakingPeriod) MystikoStakingRecord(_stakingPeriod) {}

    function stakeRecord(address _account, uint256 _stakingAmount) external returns (bool) {
        return _stakeRecord(_account, _stakingAmount);
    }

    function unstakeRecord(address _account, uint256 _stakingAmount, uint256[] calldata _nonces)
        external
        returns (bool)
    {
        return _unstakeRecord(_account, _stakingAmount, _nonces);
    }

    function claimRecord(address _account, uint256 _amount) external returns (bool) {
        return _claimRecord(_account, _amount);
    }

    function consumeClaim(address _account) external returns (uint256) {
        return _consumeClaim(_account);
    }
}

contract MystikoStakingRecordTest is Test {
    MockMystikoStakingRecord public stakingRecord;
    uint256 public constant STAKING_PERIOD = 100;
    address public user = address(0x1);
    address public admin = address(0x2);

    function setUp() public {
        stakingRecord = new MockMystikoStakingRecord(STAKING_PERIOD);
        stakingRecord.grantRole(stakingRecord.DEFAULT_ADMIN_ROLE(), admin);
        vm.startPrank(admin);
    }

    function test_StakeRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount = 1000;
        bool success = stakingRecord.stakeRecord(user, amount);
        assertTrue(success);

        (uint256 stakedBlock, uint256 stakedAmount, uint256 remaining) = stakingRecord.stakingRecords(user, 0);
        assertEq(stakedBlock, block.number);
        assertEq(stakedAmount, amount);
        assertEq(remaining, amount);
        assertEq(stakingRecord.stakingNonces(user), 1);
    }

    function test_UnstakeRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First stake
        uint256 amount = 1000;
        stakingRecord.stakeRecord(user, amount);

        // Move forward past staking period
        vm.roll(block.number + STAKING_PERIOD + 1);

        // Unstake
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        bool success = stakingRecord.unstakeRecord(user, amount, nonces);
        assertTrue(success);

        (,, uint256 remaining) = stakingRecord.stakingRecords(user, 0);
        assertEq(remaining, 0);
    }

    function test_ClaimRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount = 1000;
        bool success = stakingRecord.claimRecord(user, amount);
        assertTrue(success);

        (uint256 claimAmount, uint256 unstakeBlock, bool claimPaused) = stakingRecord.claimRecords(user);
        assertEq(claimAmount, amount);
        assertEq(unstakeBlock, block.number);
        assertFalse(claimPaused);
    }

    function test_ConsumeClaim() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First claim
        uint256 amount = 1000;
        stakingRecord.claimRecord(user, amount);

        // Move forward past claim delay
        vm.roll(block.number + stakingRecord.CLAIM_DELAY_BLOCKS() + 1);

        // Consume claim
        uint256 consumedAmount = stakingRecord.consumeClaim(user);
        assertEq(consumedAmount, amount);

        // Verify claim record is deleted
        (uint256 claimAmount,,) = stakingRecord.claimRecords(user);
        assertEq(claimAmount, 0);
    }

    function test_PauseAndUnpause() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First claim
        uint256 amount = 1000;
        stakingRecord.claimRecord(user, amount);

        // Admin pauses
        vm.stopPrank();
        vm.startPrank(admin);
        stakingRecord.pause(user);

        // Verify pause
        (,, bool claimPaused) = stakingRecord.claimRecords(user);
        assertTrue(claimPaused);

        // Admin unpauses
        stakingRecord.unpause(user);

        // Verify unpause
        (,, claimPaused) = stakingRecord.claimRecords(user);
        assertFalse(claimPaused);
    }

    function test_RevertWhen_StakeZeroAmount() public {
        vm.stopPrank();
        vm.startPrank(user);
        vm.expectRevert();
        stakingRecord.stakeRecord(user, 0);
    }

    function test_RevertWhen_UnstakeBeforePeriod() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Stake
        uint256 amount = 1000;
        stakingRecord.stakeRecord(user, amount);

        // Try to unstake before period ends
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        vm.expectRevert();
        stakingRecord.unstakeRecord(user, amount, nonces);
    }

    function test_RevertWhen_ConsumeClaimBeforeDelay() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Claim
        uint256 amount = 1000;
        stakingRecord.claimRecord(user, amount);

        // Try to consume before delay
        vm.expectRevert();
        stakingRecord.consumeClaim(user);
    }

    function test_RevertWhen_ConsumeClaimWhenPaused() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Claim
        uint256 amount = 1000;
        stakingRecord.claimRecord(user, amount);

        // Admin pauses
        vm.stopPrank();
        vm.startPrank(admin);
        stakingRecord.pause(user);

        // Try to consume while paused
        vm.stopPrank();
        vm.startPrank(user);
        vm.expectRevert();
        stakingRecord.consumeClaim(user);
    }
}
