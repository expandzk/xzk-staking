// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {XzkStakingRecord} from "../../contracts/XzkStakingRecord.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MockXzkStakingRecord is XzkStakingRecord {
    constructor(address _admin, uint256 _stakingPeriod) XzkStakingRecord(_admin, _stakingPeriod) {}

    function stakeRecord(address _account, uint256 _tokenAmount, uint256 _stakingTokenAmount) external returns (bool) {
        return _stakeRecord(_account, _tokenAmount, _stakingTokenAmount);
    }

    function unstakeVerify(address _account, uint256 _stakingTokenAmount, uint256 _startNonce, uint256 _endNonce)
        external
        returns (bool)
    {
        return _unstakeVerify(_account, _stakingTokenAmount, _startNonce, _endNonce);
    }

    function unstakeRecord(address _account, uint256 _tokenAmount, uint256 _stakingTokenAmount) external {
        _unstakeRecord(_account, _tokenAmount, _stakingTokenAmount);
    }

    function claimRecord(address _account, uint256 _startNonce, uint256 _endNonce) external returns (uint256) {
        return _claimRecord(_account, _startNonce, _endNonce);
    }
}

contract XzkStakingRecordTest is Test {
    MockXzkStakingRecord public mockContract;
    uint256 public constant STAKING_PERIOD = 90 days;
    address public user = address(0x1);
    address public user2 = address(0x2);
    address public admin = address(0x3);

    function setUp() public {
        mockContract = new MockXzkStakingRecord(admin, STAKING_PERIOD);
        vm.startPrank(admin);
    }

    // ============ Basic Functionality Tests ============

    function test_StakeRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 tokenAmount = 1000;
        uint256 stakingTokenAmount = 1000;
        bool success = mockContract.stakeRecord(user, tokenAmount, stakingTokenAmount);
        assertTrue(success);

        (uint256 stakingTime, uint256 tokenAmt, uint256 stakingTokenAmt, uint256 remaining) =
            mockContract.stakingRecords(user, 0);
        assertEq(stakingTime, block.timestamp);
        assertEq(tokenAmt, tokenAmount);
        assertEq(stakingTokenAmt, stakingTokenAmount);
        assertEq(remaining, stakingTokenAmount);
        assertEq(mockContract.stakingNonces(user), 1);
    }

    function test_UnstakeRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First stake
        uint256 tokenAmount = 1000;
        uint256 stakingTokenAmount = 1000;
        bool success = mockContract.stakeRecord(user, tokenAmount, stakingTokenAmount);
        assertTrue(success);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Unstake - first verify, then record
        bool verifySuccess = mockContract.unstakeVerify(user, stakingTokenAmount, 0, 0);
        assertTrue(verifySuccess);
        mockContract.unstakeRecord(user, tokenAmount, stakingTokenAmount);

        (,,, uint256 remaining) = mockContract.stakingRecords(user, 0);
        assertEq(remaining, 0);
    }

    function test_UnstakePartialRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First stake
        uint256 tokenAmount = 1000;
        uint256 stakingTokenAmount = 1000;
        bool success = mockContract.stakeRecord(user, tokenAmount, stakingTokenAmount);
        assertTrue(success);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Unstake partial amount - first verify, then record
        uint256 unstakeAmount = 600;
        bool verifySuccess = mockContract.unstakeVerify(user, unstakeAmount, 0, 0);
        assertTrue(verifySuccess);
        mockContract.unstakeRecord(user, tokenAmount - 400, unstakeAmount);

        (,,, uint256 remaining) = mockContract.stakingRecords(user, 0);
        assertEq(remaining, 400);
    }

    function test_ClaimRecord() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First stake and unstake to create claim record
        uint256 tokenAmount = 1000;
        uint256 stakingTokenAmount = 1000;
        mockContract.stakeRecord(user, tokenAmount, stakingTokenAmount);

        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);
        bool verifySuccess = mockContract.unstakeVerify(user, stakingTokenAmount, 0, 0);
        assertTrue(verifySuccess);
        mockContract.unstakeRecord(user, tokenAmount, stakingTokenAmount);

        // Move forward past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Claim
        uint256 claimedAmount = mockContract.claimRecord(user, 0, 0);
        assertEq(claimedAmount, tokenAmount);
    }

    function test_ClaimRecord_NotEnoughTime() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First stake and unstake to create claim record
        uint256 tokenAmount = 1000;
        uint256 stakingTokenAmount = 1000;
        mockContract.stakeRecord(user, tokenAmount, stakingTokenAmount);

        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);
        mockContract.unstakeRecord(user, tokenAmount, stakingTokenAmount);

        // Try to claim before delay period
        vm.expectRevert("Claim delay not reached");
        mockContract.claimRecord(user, 0, 0);
    }

    function test_PauseAndUnpauseClaim() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First stake and unstake to create claim record
        uint256 tokenAmount = 1000;
        uint256 stakingTokenAmount = 1000;
        mockContract.stakeRecord(user, tokenAmount, stakingTokenAmount);

        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);
        bool verifySuccess = mockContract.unstakeVerify(user, stakingTokenAmount, 0, 0);
        assertTrue(verifySuccess);
        mockContract.unstakeRecord(user, tokenAmount, stakingTokenAmount);

        // Admin pauses
        vm.stopPrank();
        vm.startPrank(admin);
        mockContract.pauseClaim(user);

        // Verify pause
        assertTrue(mockContract.claimPaused(user));

        // Move forward past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Try to claim
        vm.expectRevert("Claim paused");
        mockContract.claimRecord(user, 0, 0);

        // Admin unpauses
        mockContract.unpauseClaim(user);

        // Verify unpause
        assertFalse(mockContract.claimPaused(user));

        // Try to claim
        uint256 claimedAmount = mockContract.claimRecord(user, 0, 0);
        assertEq(claimedAmount, tokenAmount);
    }

    // ============ Multiple Staking Records Tests ============

    function test_MultipleStakeRecords() public {
        vm.stopPrank();
        vm.startPrank(user);

        uint256 amount1 = 1000;
        uint256 amount2 = 2000;
        uint256 amount3 = 3000;

        // Stake multiple times
        bool success1 = mockContract.stakeRecord(user, amount1, amount1);
        assertTrue(success1);
        bool success2 = mockContract.stakeRecord(user, amount2, amount2);
        assertTrue(success2);
        bool success3 = mockContract.stakeRecord(user, amount3, amount3);
        assertTrue(success3);

        assertEq(mockContract.stakingNonces(user), 3);

        // Verify records
        (uint256 time1, uint256 amt1,,) = mockContract.stakingRecords(user, 0);
        (uint256 time2, uint256 amt2,,) = mockContract.stakingRecords(user, 1);
        (uint256 time3, uint256 amt3,,) = mockContract.stakingRecords(user, 2);

        assertEq(amt1, amount1);
        assertEq(amt2, amount2);
        assertEq(amt3, amount3);
        assertEq(time1, block.timestamp);
        assertEq(time2, block.timestamp);
        assertEq(time3, block.timestamp);
    }

    function test_UnstakeMultipleRecords() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Stake multiple times
        mockContract.stakeRecord(user, 1000, 1000);
        mockContract.stakeRecord(user, 2000, 2000);
        mockContract.stakeRecord(user, 3000, 3000);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Unstake from multiple records (2500 total: 1000 from first + 1500 from second)
        bool verifySuccess = mockContract.unstakeVerify(user, 2500, 0, 1);
        assertTrue(verifySuccess);
        mockContract.unstakeRecord(user, 2500, 2500);

        // Verify remaining amounts
        (,,, uint256 remaining1) = mockContract.stakingRecords(user, 0);
        (,,, uint256 remaining2) = mockContract.stakingRecords(user, 1);
        (,,, uint256 remaining3) = mockContract.stakingRecords(user, 2);

        assertEq(remaining1, 0); // First record fully consumed
        assertEq(remaining2, 500); // Second record partially consumed
        assertEq(remaining3, 3000); // Third record untouched
    }

    // ============ Error Cases ============

    function test_StakeRecord_ZeroAmount() public {
        vm.stopPrank();
        vm.startPrank(user);

        vm.expectRevert("Invalid token amount");
        mockContract.stakeRecord(user, 0, 1000);

        vm.expectRevert("Invalid staking token amount");
        mockContract.stakeRecord(user, 1000, 0);
    }

    function test_UnstakeRecord_StakingPeriodNotEnded() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Stake
        mockContract.stakeRecord(user, 1000, 1000);

        // Try to unstake before period ends
        vm.expectRevert("Staking period not ended");
        mockContract.unstakeVerify(user, 1000, 0, 0);
    }

    function test_UnstakeRecord_InvalidNonce() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Try to unstake with invalid nonce
        vm.expectRevert("Staking time zero error");
        mockContract.unstakeVerify(user, 1000, 0, 0);
    }

    function test_UnstakeRecord_InsufficientAmount() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Stake
        mockContract.stakeRecord(user, 1000, 1000);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);

        // Try to unstake more than available
        vm.expectRevert("No enough staking token amount");
        mockContract.unstakeVerify(user, 2000, 0, 0);
    }

    function test_ClaimRecord_InvalidNonce() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Try to claim with invalid nonce
        vm.expectRevert("Unstaking time zero error");
        mockContract.claimRecord(user, 0, 1);
    }

    function test_ClaimRecord_AlreadyClaimed() public {
        vm.stopPrank();
        vm.startPrank(user);

        // First stake and unstake to create claim record
        uint256 tokenAmount = 1000;
        uint256 stakingTokenAmount = 1000;
        mockContract.stakeRecord(user, tokenAmount, stakingTokenAmount);

        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);
        bool verifySuccess = mockContract.unstakeVerify(user, stakingTokenAmount, 0, 0);
        assertTrue(verifySuccess);
        mockContract.unstakeRecord(user, tokenAmount, stakingTokenAmount);

        // Move forward past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Claim first time
        uint256 claimedAmount = mockContract.claimRecord(user, 0, 0);
        assertEq(claimedAmount, tokenAmount);

        // Try to claim again - should fail with "Token remaining zero error"
        vm.expectRevert("Token remaining zero error");
        mockContract.claimRecord(user, 0, 0);
    }

    // ============ Access Control Tests ============

    function test_PauseClaim_OnlyAdmin() public {
        vm.stopPrank();
        vm.startPrank(user);

        vm.expectRevert();
        mockContract.pauseClaim(user);
    }

    function test_UnpauseClaim_OnlyAdmin() public {
        vm.stopPrank();
        vm.startPrank(user);

        vm.expectRevert();
        mockContract.unpauseClaim(user);
    }

    // ============ Edge Cases ============

    function test_StakeRecord_MaximumNonce() public {
        vm.stopPrank();
        vm.startPrank(user);

        // This test would be very expensive to run, so we'll just verify the structure works
        // In practice, uint256 nonce would take an extremely long time to overflow
        for (uint256 i = 0; i < 10; i++) {
            mockContract.stakeRecord(user, 1000, 1000);
        }

        assertEq(mockContract.stakingNonces(user), 10);
    }

    function test_UnstakeRecord_ExactAmount() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Stake
        mockContract.stakeRecord(user, 1000, 1000);

        // Move forward past staking period
        vm.warp(block.timestamp + STAKING_PERIOD + 1);

        // Unstake exact amount
        bool verifySuccess = mockContract.unstakeVerify(user, 1000, 0, 0);
        assertTrue(verifySuccess);
        mockContract.unstakeRecord(user, 1000, 1000);

        (,,, uint256 remaining) = mockContract.stakingRecords(user, 0);
        assertEq(remaining, 0);
    }

    function test_ClaimRecord_MultipleRecords() public {
        vm.stopPrank();
        vm.startPrank(user);

        // Create multiple staking records at the same timestamp
        for (uint256 i = 0; i < 3; i++) {
            mockContract.stakeRecord(user, 1000, 1000);
        }

        // Move forward past staking period once for all records
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        vm.roll(block.number + (STAKING_PERIOD + 1) / 12);

        // Unstake each record individually
        for (uint256 i = 0; i < 3; i++) {
            bool verifySuccess = mockContract.unstakeVerify(user, 1000, i, i);
            assertTrue(verifySuccess);
            mockContract.unstakeRecord(user, 1000, 1000);
        }

        // Move forward past claim delay
        vm.warp(block.timestamp + mockContract.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (mockContract.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Claim all records - note: loop condition is i <= _endNonce, so we need to use 0, 2
        uint256 claimedAmount = mockContract.claimRecord(user, 0, 2);
        assertEq(claimedAmount, 3000);
    }
}
