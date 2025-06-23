// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MystikoStakingRecord} from "../../contracts/MystikoStakingRecord.sol";

contract MockMystikoStakingRecord is MystikoStakingRecord {
    constructor(address _admin, uint256 _stakingPeriod) MystikoStakingRecord(_admin, _stakingPeriod) {}

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
    MockMystikoStakingRecord public mockContract;
    uint256 public constant STAKING_PERIOD = 90 days;
    address public user = address(0x1);
    address public user2 = address(0x2);
    address public admin = address(0x3);

    function setUp() public {
        mockContract = new MockMystikoStakingRecord(admin, STAKING_PERIOD);
        vm.startPrank(admin);
    }

    // ============ Basic Functionality Tests ============

    function test_StakeRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount = 1000;
        bool success = mockContract.stakeRecord(user, amount);
        assertTrue(success);

        (uint256 stakedBlock, uint256 stakedAmount, uint256 remaining) = mockContract.stakingRecords(user, 0);
        assertEq(stakedBlock, block.number);
        assertEq(stakedAmount, amount);
        assertEq(remaining, amount);
        assertEq(mockContract.stakingNonces(user), 1);
    }

    function test_UnstakeRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First stake
        uint256 amount = 1000;
        bool success = mockContract.stakeRecord(user, amount);
        assertTrue(success);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Unstake
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        bool success2 = mockContract.unstakeRecord(user, amount, nonces);
        assertTrue(success2);

        (,, uint256 remaining) = mockContract.stakingRecords(user, 0);
        assertEq(remaining, 0);
    }

    function test_UnstakePartialRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First stake
        uint256 amount = 1000;
        bool success = mockContract.stakeRecord(user, amount);
        assertTrue(success);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Unstake
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        bool success2 = mockContract.unstakeRecord(user, amount - 100, nonces);
        assertTrue(success2);

        (,, uint256 remaining) = mockContract.stakingRecords(user, 0);
        assertEq(remaining, 100);
    }

    function test_ClaimRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount = 1000;
        bool success = mockContract.claimRecord(user, amount);
        assertTrue(success);

        (uint256 unstakeBlock, uint256 claimAmount, bool claimPaused) = mockContract.claimRecords(user);
        assertEq(claimAmount, amount);
        assertEq(unstakeBlock, block.number);
        assertFalse(claimPaused);
    }

    function test_ConsumeClaim() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First claim
        uint256 amount = 1000;
        bool success = mockContract.claimRecord(user, amount);
        assertTrue(success);

        // Move forward past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Consume claim
        uint256 consumedAmount = mockContract.consumeClaim(user);
        assertEq(consumedAmount, amount);

        // Verify claim record is deleted
        (uint256 claimAmount,,) = mockContract.claimRecords(user);
        assertEq(claimAmount, 0);
    }

    function test_PauseAndUnpause() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First claim
        uint256 amount = 1000;
        bool success = mockContract.claimRecord(user, amount);
        assertTrue(success);

        // Admin pauses
        vm.stopPrank();
        vm.startPrank(admin);
        mockContract.pauseClaim(user);

        // Verify pause
        (,, bool claimPaused) = mockContract.claimRecords(user);
        assertTrue(claimPaused);

        // Move forward past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Try to consume claim
        vm.expectRevert("MystikoClaim: Claim paused");
        mockContract.consumeClaim(user);

        // Admin unpauses
        mockContract.unpauseClaim(user);

        // Verify unpause
        (,, claimPaused) = mockContract.claimRecords(user);
        assertFalse(claimPaused);

        // Try to consume claim
        uint256 consumedAmount2 = mockContract.consumeClaim(user);
        assertEq(consumedAmount2, amount);
    }

    // ============ Multiple Staking Records Tests ============

    function test_MultipleStakeRecords() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount1 = 1000;
        uint256 amount2 = 2000;
        uint256 amount3 = 3000;

        // Stake multiple times
        bool success1 = mockContract.stakeRecord(user, amount1);
        assertTrue(success1);
        bool success2 = mockContract.stakeRecord(user, amount2);
        assertTrue(success2);
        bool success3 = mockContract.stakeRecord(user, amount3);
        assertTrue(success3);

        assertEq(mockContract.stakingNonces(user), 3);

        // Verify all records
        (, uint256 stakedAmount1, uint256 remaining1) = mockContract.stakingRecords(user, 0);
        (, uint256 stakedAmount2, uint256 remaining2) = mockContract.stakingRecords(user, 1);
        (, uint256 stakedAmount3, uint256 remaining3) = mockContract.stakingRecords(user, 2);

        assertEq(stakedAmount1, amount1);
        assertEq(stakedAmount2, amount2);
        assertEq(stakedAmount3, amount3);
        assertEq(remaining1, amount1);
        assertEq(remaining2, amount2);
        assertEq(remaining3, amount3);
    }

    function test_UnstakeMultipleRecords() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount1 = 1000;
        uint256 amount2 = 2000;

        // Stake multiple times
        bool success1 = mockContract.stakeRecord(user, amount1);
        assertTrue(success1);
        bool success2 = mockContract.stakeRecord(user, amount2);
        assertTrue(success2);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Unstake from first record
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        bool success = mockContract.unstakeRecord(user, amount1, nonces);
        assertTrue(success);

        // Verify first record is consumed
        (,, uint256 remaining1) = mockContract.stakingRecords(user, 0);
        assertEq(remaining1, 0);

        // Verify second record is intact
        (,, uint256 remaining2) = mockContract.stakingRecords(user, 1);
        assertEq(remaining2, amount2);
    }

    function test_UnstakePartialFromMultipleRecords() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount1 = 1000;
        uint256 amount2 = 2000;
        uint256 amount3 = 3000;
        uint256 totalAmount = amount1 + amount2 + amount3;

        // Stake multiple times
        bool success1 = mockContract.stakeRecord(user, amount1);
        assertTrue(success1);
        bool success2 = mockContract.stakeRecord(user, amount2);
        assertTrue(success2);
        bool success3 = mockContract.stakeRecord(user, amount3);
        assertTrue(success3);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Unstake partial amount that spans multiple records
        uint256[] memory nonces = new uint256[](3);
        nonces[0] = 0;
        nonces[1] = 1;
        nonces[2] = 2;
        uint256 unstakeAmount = totalAmount - 100; // 5000 from third
        bool success = mockContract.unstakeRecord(user, unstakeAmount, nonces);
        assertTrue(success);

        // Verify first record is fully consumed
        (,, uint256 remaining1) = mockContract.stakingRecords(user, 0);
        assertEq(remaining1, 0);

        // Verify second record is partially consumed
        (,, uint256 remaining2) = mockContract.stakingRecords(user, 1);
        assertEq(remaining2, 0);

        // Verify third record is partially consumed
        (,, uint256 remaining3) = mockContract.stakingRecords(user, 2);
        assertEq(remaining3, 100);
    }

    function test_UnstakeAllFromMultipleRecords() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount1 = 1000;
        uint256 amount2 = 2000;
        uint256 amount3 = 3000;
        uint256 totalAmount = amount1 + amount2 + amount3;

        // Stake multiple times
        bool success1 = mockContract.stakeRecord(user, amount1);
        assertTrue(success1);
        bool success2 = mockContract.stakeRecord(user, amount2);
        assertTrue(success2);
        bool success3 = mockContract.stakeRecord(user, amount3);
        assertTrue(success3);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Unstake partial amount that spans multiple records
        uint256[] memory nonces = new uint256[](3);
        nonces[0] = 0;
        nonces[1] = 1;
        nonces[2] = 2;
        uint256 unstakeAmount = totalAmount;
        bool success = mockContract.unstakeRecord(user, unstakeAmount, nonces);
        assertTrue(success);

        // Verify first record is fully consumed
        (,, uint256 remaining1) = mockContract.stakingRecords(user, 0);
        assertEq(remaining1, 0);

        // Verify second record is partially consumed
        (,, uint256 remaining2) = mockContract.stakingRecords(user, 1);
        assertEq(remaining2, 0);

        // Verify third record is partially consumed
        (,, uint256 remaining3) = mockContract.stakingRecords(user, 2);
        assertEq(remaining3, 0);
    }

    // ============ Edge Cases and Boundary Tests ============

    function test_StakeRecordWithMaxAmount() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 maxAmount = type(uint256).max;
        bool success = mockContract.stakeRecord(user, maxAmount);
        assertTrue(success);

        (, uint256 stakedAmount, uint256 remaining) = mockContract.stakingRecords(user, 0);
        assertEq(stakedAmount, maxAmount);
        assertEq(remaining, maxAmount);
    }

    function test_ClaimRecordWithMaxAmount() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 maxAmount = type(uint256).max;
        bool success = mockContract.claimRecord(user, maxAmount);
        assertTrue(success);

        (, uint256 claimAmount,) = mockContract.claimRecords(user);
        assertEq(claimAmount, maxAmount);
    }

    function test_ConsumeClaimWithMaxAmount() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 maxAmount = type(uint256).max;
        mockContract.claimRecord(user, maxAmount);

        // Move forward past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        uint256 consumedAmount = mockContract.consumeClaim(user);
        assertEq(consumedAmount, maxAmount);
    }

    function test_StakeRecordAtBlockBoundary() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Stake at block 1
        uint256 block1Timestamp = 243431;
        vm.warp(block1Timestamp);
        vm.roll(block.number + 1);
        mockContract.stakeRecord(user, 1000);

        // Stake at block 2
        uint256 block2Timestamp = block1Timestamp + 1;
        vm.warp(block2Timestamp);
        vm.roll(block.number + 1);
        mockContract.stakeRecord(user, 2000);

        (uint256 stakedTime1,,) = mockContract.stakingRecords(user, 0);
        (uint256 stakedTime2,,) = mockContract.stakingRecords(user, 1);

        assertEq(stakedTime1, block1Timestamp);
        assertEq(stakedTime2, block2Timestamp);
    }

    // ============ Error Handling Tests ============

    function test_RevertWhen_StakeZeroAmount() public {
        vm.stopPrank();
        vm.startPrank(user);
        vm.expectRevert("MystikoClaim: Invalid staking token amount");
        mockContract.stakeRecord(user, 0);
    }

    function test_RevertWhen_UnstakeBeforePeriod() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Stake
        uint256 amount = 1000;
        mockContract.stakeRecord(user, amount);

        vm.warp(block.timestamp + STAKING_PERIOD);
        vm.roll(block.number + (STAKING_PERIOD) / 12);

        // Try to unstake before period ends
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        vm.expectRevert("MystikoClaim: Staking period not ended");
        mockContract.unstakeRecord(user, amount, nonces);
    }

    function test_RevertWhen_UnstakeNonExistentRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 999; // Non-existent nonce
        vm.expectRevert("MystikoClaim: Staking record not found");
        mockContract.unstakeRecord(user, 1000, nonces);
    }

    function test_RevertWhen_UnstakeInsufficientAmount() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount = 1000;
        mockContract.stakeRecord(user, amount);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Try to unstake more than available
        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        vm.expectRevert("MystikoClaim: no enough staking amount");
        mockContract.unstakeRecord(user, amount + 1, nonces);
    }

    function test_RevertWhen_ConsumeClaimBeforeDelay() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Claim
        uint256 amount = 1000;
        mockContract.claimRecord(user, amount);

        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS());
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS()) / 12);

        // Try to consume before delay
        vm.expectRevert("MystikoClaim: Claim delay not reached");
        mockContract.consumeClaim(user);
    }

    function test_RevertWhen_ConsumeClaimWhenPaused() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Claim
        uint256 amount = 1000;
        mockContract.claimRecord(user, amount);

        // Admin pauses
        vm.stopPrank();
        vm.startPrank(admin);
        mockContract.pauseClaim(user);

        // Move forward past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Try to consume while paused
        vm.stopPrank();
        vm.startPrank(user);
        vm.expectRevert("MystikoClaim: Claim paused");
        mockContract.consumeClaim(user);
    }

    function test_RevertWhen_ConsumeClaimWithNoAmount() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Move forward past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Try to consume without claiming first
        vm.expectRevert("MystikoClaim: No claimable amount");
        mockContract.consumeClaim(user);
    }

    function test_RevertWhen_ConsumeClaimAfterConsuming() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Claim and consume
        uint256 amount = 1000;
        mockContract.claimRecord(user, amount);

        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);
        mockContract.consumeClaim(user);

        // Try to consume again
        vm.expectRevert("MystikoClaim: No claimable amount");
        mockContract.consumeClaim(user);
    }

    // ============ Permission Tests ============

    function test_RevertWhen_PauseByNonAdmin() public {
        vm.stopPrank();
        vm.startPrank(user);

        vm.expectRevert();
        mockContract.pauseClaim(user);
    }

    function test_RevertWhen_UnpauseByNonAdmin() public {
        vm.stopPrank();
        vm.startPrank(user);

        vm.expectRevert();
        mockContract.unpauseClaim(user);
    }

    function test_PauseAndUnpauseMultipleAccounts() public {
        vm.stopPrank();
        vm.startPrank(admin);

        // Pause multiple accounts
        mockContract.pauseClaim(user);
        mockContract.pauseClaim(user2);

        // Verify both are paused
        (,, bool claimPaused1) = mockContract.claimRecords(user);
        (,, bool claimPaused2) = mockContract.claimRecords(user2);
        assertTrue(claimPaused1);
        assertTrue(claimPaused2);

        // Unpause both
        mockContract.unpauseClaim(user);
        mockContract.unpauseClaim(user2);

        // Verify both are unpaused
        (,, claimPaused1) = mockContract.claimRecords(user);
        (,, claimPaused2) = mockContract.claimRecords(user2);
        assertFalse(claimPaused1);
        assertFalse(claimPaused2);
    }

    // ============ Complex Scenarios Tests ============

    function test_CompleteStakingLifecycle() public {
        vm.stopPrank();
        vm.startPrank(user);

        // 1. Stake multiple amounts
        uint256 amount1 = 1000;
        uint256 amount2 = 2000;
        mockContract.stakeRecord(user, amount1);
        mockContract.stakeRecord(user, amount2);

        // 2. Move past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // 3. Unstake partial amount
        uint256[] memory nonces = new uint256[](2);
        nonces[0] = 0;
        nonces[1] = 1;
        uint256 unstakeAmount = 1500;
        bool success = mockContract.unstakeRecord(user, unstakeAmount, nonces);
        assertTrue(success);

        // 4. Claim the unstaked amount
        mockContract.claimRecord(user, unstakeAmount);

        // 5. Move past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // 6. Consume the claim
        uint256 consumedAmount = mockContract.consumeClaim(user);
        assertEq(consumedAmount, unstakeAmount);

        // 7. Verify remaining staking amount
        (,, uint256 remaining1) = mockContract.stakingRecords(user, 0);
        (,, uint256 remaining2) = mockContract.stakingRecords(user, 1);
        assertEq(remaining1, 0); // Fully consumed
        assertEq(remaining2, amount2 - 500); // Partially consumed

        // 8. unstake the remaining amount
        uint256[] memory nonces2 = new uint256[](1);
        nonces2[0] = 1;
        bool success2 = mockContract.unstakeRecord(user, amount2 - 500, nonces2);
        assertTrue(success2);

        // 9. claim the remaining amount
        mockContract.claimRecord(user, amount2 - 500);

        // 10. move past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // 11. consume the remaining amount
        uint256 consumedAmount2 = mockContract.consumeClaim(user);
        assertEq(consumedAmount2, amount2 - 500);
    }

    function test_StakeUnstakeClaimWithPause() public {
        vm.stopPrank();
        vm.startPrank(user);

        // 1. Stake and unstake
        uint256 amount = 1000;
        mockContract.stakeRecord(user, amount);

        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 0;
        mockContract.unstakeRecord(user, amount, nonces);

        // 2. Claim
        mockContract.claimRecord(user, amount);

        // 3. Admin pauses
        vm.stopPrank();
        vm.startPrank(admin);
        mockContract.pauseClaim(user);
        vm.stopPrank();

        // 4. Try to consume while paused
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        vm.startPrank(user);
        vm.expectRevert("MystikoClaim: Claim paused");
        mockContract.consumeClaim(user);

        // 5. Admin unpauses
        vm.stopPrank();
        vm.startPrank(admin);
        mockContract.unpauseClaim(user);

        // 6. Now consume should work
        vm.stopPrank();
        vm.startPrank(user);
        uint256 consumedAmount = mockContract.consumeClaim(user);
        assertEq(consumedAmount, amount);
    }

    function test_MultipleUsersStaking() public {
        vm.stopPrank();

        // User 1 stakes
        vm.startPrank(user);
        mockContract.stakeRecord(user, 1000);
        vm.stopPrank();

        // User 2 stakes
        vm.startPrank(user2);
        mockContract.stakeRecord(user2, 2000);
        vm.stopPrank();

        // Verify both have records
        assertEq(mockContract.stakingNonces(user), 1);
        assertEq(mockContract.stakingNonces(user2), 1);

        (uint256 stakedBlock1, uint256 stakedAmount1,) = mockContract.stakingRecords(user, 0);
        (uint256 stakedBlock2, uint256 stakedAmount2,) = mockContract.stakingRecords(user2, 0);

        assertEq(stakedAmount1, 1000);
        assertEq(stakedAmount2, 2000);
        assertEq(stakedBlock1, stakedBlock2); // Same block
    }
}
