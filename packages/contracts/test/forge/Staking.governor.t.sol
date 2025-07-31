// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {XzkStaking} from "../../contracts/XzkStaking.sol";
import {MockToken} from "../../contracts/mocks/MockToken.sol";
import {MystikoGovernorRegistry} from
    "../../lib/mystiko-governance/packages/contracts/contracts/impl/MystikoGovernorRegistry.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {GovernanceErrors} from "../../lib/mystiko-governance/packages/contracts/contracts/GovernanceErrors.sol";

contract StakingGovernorTest is Test {
    XzkStaking public staking;
    MockToken public mockToken;
    MystikoGovernorRegistry public daoRegistry;

    address public deployer;
    address public dao;
    address public user1;
    address public user2;
    address public nonDao;

    event ClaimedToDao(address indexed account, uint256 amount);
    event StakingPausedByDao();
    event StakingUnpausedByDao();
    event ClaimToDaoEnabled();
    event ClaimToDaoDisabled();

    function setUp() public {
        deployer = makeAddr("deployer");
        dao = makeAddr("dao");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        nonDao = makeAddr("nonDao");

        // Deploy DAO registry
        vm.startPrank(deployer);
        daoRegistry = new MystikoGovernorRegistry();
        daoRegistry.transferOwnerToDAO(dao);
        vm.stopPrank();

        // Deploy mock token
        vm.startPrank(deployer);
        mockToken = new MockToken();
        vm.stopPrank();

        // Deploy staking contract
        vm.startPrank(deployer);
        staking = new XzkStaking(
            address(daoRegistry),
            deployer,
            mockToken,
            "Mystiko Staking Vote Token 90D",
            "svXZK-90D",
            90 days, // staking period
            1500, // total factor
            block.timestamp + 5 days // start time
        );
        vm.stopPrank();

        // Transfer tokens to users for testing
        vm.startPrank(deployer);
        mockToken.transfer(user1, 10000 ether);
        mockToken.transfer(user2, 10000 ether);
        mockToken.transfer(address(staking), 500_000_000 ether); // Transfer half of total supply to staking contract
        staking.enableClaimToDao();
        vm.stopPrank();
    }

    // ============ claimToDao Tests ============

    function test_claimToDao_Success() public {
        uint256 claimAmount = 100 ether;
        uint256 daoBalanceBefore = mockToken.balanceOf(dao);

        vm.expectEmit(address(staking));
        emit ClaimedToDao(dao, claimAmount);

        vm.prank(dao);
        staking.claimToDao(claimAmount);

        uint256 daoBalanceAfter = mockToken.balanceOf(dao);
        assertEq(daoBalanceAfter - daoBalanceBefore, claimAmount, "DAO should receive the claimed amount");
    }

    function test_enable_disable_ClaimToDao_Success() public {
        vm.expectEmit(address(staking));
        emit ClaimToDaoDisabled();
        vm.startPrank(deployer);
        staking.disableClaimToDao();
        vm.stopPrank();
        assertFalse(staking.isClaimToDaoEnabled(), "Claim to dao should be disabled");

        vm.expectRevert("XzkStaking: Claim to dao is disabled");
        vm.prank(dao);
        staking.claimToDao(1 ether);

        vm.expectEmit(address(staking));
        emit ClaimToDaoEnabled();
        vm.startPrank(deployer);
        staking.enableClaimToDao();
        vm.stopPrank();
        assertTrue(staking.isClaimToDaoEnabled(), "Claim to dao should be enabled");

        uint256 daoBalanceBefore = mockToken.balanceOf(dao);
        vm.expectEmit(address(staking));
        emit ClaimedToDao(dao, 1 ether);
        vm.prank(dao);
        staking.claimToDao(1 ether);
        uint256 daoBalanceAfter = mockToken.balanceOf(dao);
        assertEq(daoBalanceAfter - daoBalanceBefore, 1 ether, "DAO should receive the claimed amount");
    }

    function test_enable_disable_ClaimToDao_OnlyAdmin() public {
        vm.expectRevert();
        vm.prank(dao);
        staking.disableClaimToDao();
        assertTrue(staking.isClaimToDaoEnabled(), "Claim to dao should be enabled");

        vm.expectRevert();
        vm.prank(dao);
        staking.enableClaimToDao();
        assertTrue(staking.isClaimToDaoEnabled(), "Claim to dao should be enabled");

        vm.prank(deployer);
        staking.disableClaimToDao();
        assertFalse(staking.isClaimToDaoEnabled(), "Claim to dao should be disabled");

        vm.prank(deployer);
        staking.enableClaimToDao();
        assertTrue(staking.isClaimToDaoEnabled(), "Claim to dao should be enabled");
    }

    function test_claimToDao_OnlyMystikoDAO() public {
        uint256 claimAmount = 100 ether;

        // Non-DAO address should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(nonDao);
        staking.claimToDao(claimAmount);

        // User1 should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(user1);
        staking.claimToDao(claimAmount);

        // Deployer should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(deployer);
        staking.claimToDao(claimAmount);
    }

    function test_claimToDao_InvalidAmount() public {
        // Zero amount should fail
        vm.expectRevert("XzkStaking: Invalid amount");
        vm.prank(dao);
        staking.claimToDao(0);
    }

    function test_claimToDao_ExcessiveAmount() public {
        uint256 excessiveAmount = 5000 ether; // Half of what we funded the contract with

        // Should succeed as contract has enough balance
        vm.prank(dao);
        staking.claimToDao(excessiveAmount);

        uint256 daoBalance = mockToken.balanceOf(dao);
        assertEq(daoBalance, excessiveAmount, "DAO should receive the claimed amount");
    }

    function test_claimToDao_MultipleClaims() public {
        uint256 claimAmount1 = 50 ether;
        uint256 claimAmount2 = 75 ether;

        vm.startPrank(dao);

        staking.claimToDao(claimAmount1);
        staking.claimToDao(claimAmount2);

        vm.stopPrank();

        uint256 daoBalance = mockToken.balanceOf(dao);
        assertEq(daoBalance, claimAmount1 + claimAmount2, "DAO should receive total claimed amounts");
    }

    // ============ pauseStaking Tests ============

    function test_pauseStaking_Success() public {
        assertFalse(staking.isStakingPaused(), "Staking should not be paused initially");

        vm.expectEmit(address(staking));
        emit StakingPausedByDao();

        vm.prank(dao);
        staking.pauseStaking();

        assertTrue(staking.isStakingPaused(), "Staking should be paused");
    }

    function test_pauseStaking_OnlyMystikoDAO() public {
        // Non-DAO address should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(nonDao);
        staking.pauseStaking();

        // User1 should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(user1);
        staking.pauseStaking();

        // Deployer should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(deployer);
        staking.pauseStaking();
    }

    function test_pauseStaking_AlreadyPaused() public {
        // Pause first time
        vm.prank(dao);
        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "Staking should be paused");

        // Pause again should work (no revert)
        vm.prank(dao);
        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "Staking should remain paused");
    }

    // ============ unpauseStaking Tests ============

    function test_unpauseStaking_Success() public {
        // First pause staking
        vm.prank(dao);
        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "Staking should be paused");

        vm.expectEmit(address(staking));
        emit StakingUnpausedByDao();

        vm.prank(dao);
        staking.unpauseStaking();

        assertFalse(staking.isStakingPaused(), "Staking should be unpaused");
    }

    function test_unpauseStaking_OnlyMystikoDAO() public {
        // Non-DAO address should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(nonDao);
        staking.unpauseStaking();

        // User1 should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(user1);
        staking.unpauseStaking();

        // Deployer should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(deployer);
        staking.unpauseStaking();
    }

    function test_unpauseStaking_NotPaused() public {
        // Unpause when not paused should work (no revert)
        vm.prank(dao);
        staking.unpauseStaking();

        assertFalse(staking.isStakingPaused(), "Staking should remain unpaused");
    }

    // ============ pauseClaim Tests ============

    function test_pauseClaim_Success() public {
        assertFalse(staking.claimPaused(user1), "User should not be paused initially");

        vm.prank(deployer);
        staking.pauseClaim(user1);

        assertTrue(staking.claimPaused(user1), "User should be paused");
    }

    function test_pauseClaim_OnlyAdmin() public {
        // Non-admin should fail
        vm.expectRevert();
        vm.prank(nonDao);
        staking.pauseClaim(user1);

        // User should fail
        vm.expectRevert();
        vm.prank(user1);
        staking.pauseClaim(user1);

        // DAO should fail (not admin)
        vm.expectRevert();
        vm.prank(dao);
        staking.pauseClaim(user1);
    }

    function test_pauseClaim_AlreadyPaused() public {
        // Pause first time
        vm.prank(deployer);
        staking.pauseClaim(user1);
        assertTrue(staking.claimPaused(user1), "User should be paused");

        // Pause again should work (no revert)
        vm.prank(deployer);
        staking.pauseClaim(user1);
        assertTrue(staking.claimPaused(user1), "User should remain paused");
    }

    // ============ unpauseClaim Tests ============

    function test_unpauseClaim_Success() public {
        // First pause user
        vm.prank(deployer);
        staking.pauseClaim(user1);
        assertTrue(staking.claimPaused(user1), "User should be paused");

        vm.prank(deployer);
        staking.unpauseClaim(user1);

        assertFalse(staking.claimPaused(user1), "User should be unpaused");
    }

    function test_unpauseClaim_OnlyAdmin() public {
        // Non-admin should fail
        vm.expectRevert();
        vm.prank(nonDao);
        staking.unpauseClaim(user1);

        // User should fail
        vm.expectRevert();
        vm.prank(user1);
        staking.unpauseClaim(user1);

        // DAO should fail (not admin)
        vm.expectRevert();
        vm.prank(dao);
        staking.unpauseClaim(user1);
    }

    function test_unpauseClaim_NotPaused() public {
        // Unpause when not paused should work (no revert)
        vm.prank(deployer);
        staking.unpauseClaim(user1);

        assertFalse(staking.claimPaused(user1), "User should remain unpaused");
    }

    // ============ Integration Tests ============

    function test_PauseStaking_ThenStake() public {
        // Pause staking
        vm.prank(dao);
        staking.pauseStaking();

        // Try to stake while paused
        vm.startPrank(user1);
        mockToken.approve(address(staking), 100 ether);
        vm.expectRevert("XzkStaking: paused");
        staking.stake(100 ether);
        vm.stopPrank();

        // Unpause staking
        vm.prank(dao);
        staking.unpauseStaking();

        // Now stake should work
        vm.startPrank(user1);
        mockToken.approve(address(staking), 100 ether);
        bool success = staking.stake(100 ether);
        assertTrue(success, "Stake should succeed after unpause");
        vm.stopPrank();
    }

    function test_PauseClaim_ThenClaim() public {
        // First stake and unstake to create claim record
        vm.startPrank(user1);
        mockToken.approve(address(staking), 100 ether);
        staking.stake(100 ether);

        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(100 ether, 0, 0);

        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Pause claim for user
        vm.stopPrank();
        vm.prank(deployer);
        staking.pauseClaim(user1);

        // Try to claim while paused
        vm.startPrank(user1);
        vm.expectRevert("Claim paused");
        staking.claim(user1, 0, 0);
        vm.stopPrank();

        // Unpause claim
        vm.prank(deployer);
        staking.unpauseClaim(user1);

        // Now claim should work
        vm.startPrank(user1);
        bool success = staking.claim(user1, 0, 0);
        assertTrue(success, "Claim should succeed after unpause");
        vm.stopPrank();
    }

    function test_MultipleUsers_PauseUnpause() public {
        // Pause multiple users
        vm.startPrank(deployer);
        staking.pauseClaim(user1);
        staking.pauseClaim(user2);
        vm.stopPrank();

        assertTrue(staking.claimPaused(user1), "User1 should be paused");
        assertTrue(staking.claimPaused(user2), "User2 should be paused");

        // Unpause multiple users
        vm.startPrank(deployer);
        staking.unpauseClaim(user1);
        staking.unpauseClaim(user2);
        vm.stopPrank();

        assertFalse(staking.claimPaused(user1), "User1 should be unpaused");
        assertFalse(staking.claimPaused(user2), "User2 should be unpaused");
    }

    // ============ Edge Cases ============

    function test_claimToDao_MaxAmount() public {
        uint256 maxAmount = mockToken.balanceOf(address(staking));

        vm.prank(dao);
        staking.claimToDao(maxAmount);

        uint256 daoBalance = mockToken.balanceOf(dao);
        assertEq(daoBalance, maxAmount, "DAO should receive the max amount");
    }

    function test_claimToDao_MoreThanAvailable() public {
        uint256 excessiveAmount = mockToken.balanceOf(address(staking)) + 1 ether;

        // Should fail as contract doesn't have enough balance
        vm.expectRevert();
        vm.prank(dao);
        staking.claimToDao(excessiveAmount);
    }

    function test_PauseStaking_Unpause_Stake_Unstake() public {
        // Complete lifecycle with pause/unpause
        vm.startPrank(user1);
        mockToken.approve(address(staking), 100 ether);

        // Pause staking
        vm.stopPrank();
        vm.prank(dao);
        staking.pauseStaking();

        // Try to stake (should fail)
        vm.startPrank(user1);
        vm.expectRevert("XzkStaking: paused");
        staking.stake(100 ether);
        vm.stopPrank();

        // Unpause staking
        vm.prank(dao);
        staking.unpauseStaking();

        // Stake should work now
        vm.startPrank(user1);
        bool success = staking.stake(100 ether);
        assertTrue(success, "Stake should succeed after unpause");

        // Move forward past staking period
        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);

        // Unstake should work
        success = staking.unstake(100 ether, 0, 0);
        assertTrue(success, "Unstake should succeed");
        vm.stopPrank();
    }

    function test_PauseClaim_Unpause_Claim() public {
        // Complete lifecycle with pause/unpause for claims
        vm.startPrank(user1);
        mockToken.approve(address(staking), 100 ether);
        staking.stake(100 ether);

        vm.warp(block.timestamp + staking.STAKING_PERIOD_SECONDS() + 1);
        vm.roll(block.number + (staking.STAKING_PERIOD_SECONDS() + 1) / 12);
        staking.unstake(100 ether, 0, 0);

        vm.warp(block.timestamp + staking.CLAIM_DELAY_SECONDS() + 1);
        vm.roll(block.number + (staking.CLAIM_DELAY_SECONDS() + 1) / 12);

        // Pause claim
        vm.stopPrank();
        vm.prank(deployer);
        staking.pauseClaim(user1);

        // Try to claim (should fail)
        vm.startPrank(user1);
        vm.expectRevert("Claim paused");
        staking.claim(user1, 0, 1);
        vm.stopPrank();

        // Unpause claim
        vm.prank(deployer);
        staking.unpauseClaim(user1);

        // Claim should work now
        vm.startPrank(user1);
        bool success = staking.claim(user1, 0, 0);
        assertTrue(success, "Claim should succeed after unpause");
        vm.stopPrank();
    }

    // ============ Events Tests ============

    function test_claimToDao_EmitsEvent() public {
        uint256 claimAmount = 100 ether;

        vm.expectEmit(true, false, false, true);
        emit ClaimedToDao(dao, claimAmount);

        vm.prank(dao);
        staking.claimToDao(claimAmount);
    }

    function test_pauseStaking_EmitsEvent() public {
        vm.expectEmit(false, false, false, false);
        emit StakingPausedByDao();

        vm.prank(dao);
        staking.pauseStaking();
    }

    function test_unpauseStaking_EmitsEvent() public {
        // First pause
        vm.prank(dao);
        staking.pauseStaking();

        vm.expectEmit(false, false, false, false);
        emit StakingUnpausedByDao();

        vm.prank(dao);
        staking.unpauseStaking();
    }

    // ============ Access Control Tests ============

    function test_AccessControl_DeployerIsAdmin() public {
        // Deployer should be able to pause/unpause claims
        vm.prank(deployer);
        staking.pauseClaim(user1);

        vm.prank(deployer);
        staking.unpauseClaim(user1);

        // Should not revert
        assertFalse(staking.claimPaused(user1), "User should be unpaused");
    }

    function test_AccessControl_DAOIsNotAdmin() public {
        // DAO should not be able to pause/unpause claims
        vm.expectRevert();
        vm.prank(dao);
        staking.pauseClaim(user1);

        vm.expectRevert();
        vm.prank(dao);
        staking.unpauseClaim(user1);
    }

    function test_AccessControl_UsersAreNotAdmin() public {
        // Users should not be able to pause/unpause claims
        vm.expectRevert();
        vm.prank(user1);
        staking.pauseClaim(user2);

        vm.expectRevert();
        vm.prank(user1);
        staking.unpauseClaim(user2);
    }

    // ============ TOTAL CLAIMED TESTS ============

    function test_TotalClaimed_Initial() public {
        // Initially totalClaimed should be 0
        assertEq(staking.totalClaimed(), 0, "Initial totalClaimed should be 0");
    }

    function test_TotalClaimed_AfterDaoClaim() public {
        // Setup: fund the contract
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

    function test_TotalClaimed_MultipleDaoClaims() public {
        // Setup: multiple DAO claims
        uint256 claimAmount1 = 500 ether;
        uint256 claimAmount2 = 750 ether;
        uint256 claimAmount3 = 1000 ether;

        // First DAO claim
        uint256 totalClaimedBefore1 = staking.totalClaimed();
        vm.prank(dao);
        staking.claimToDao(claimAmount1);
        uint256 totalClaimedAfter1 = staking.totalClaimed();
        assertEq(
            totalClaimedAfter1, totalClaimedBefore1 + claimAmount1, "totalClaimed should increase after first DAO claim"
        );

        // Second DAO claim
        uint256 totalClaimedBefore2 = staking.totalClaimed();
        vm.prank(dao);
        staking.claimToDao(claimAmount2);
        uint256 totalClaimedAfter2 = staking.totalClaimed();
        assertEq(
            totalClaimedAfter2,
            totalClaimedBefore2 + claimAmount2,
            "totalClaimed should increase after second DAO claim"
        );

        // Third DAO claim
        uint256 totalClaimedBefore3 = staking.totalClaimed();
        vm.prank(dao);
        staking.claimToDao(claimAmount3);
        uint256 totalClaimedAfter3 = staking.totalClaimed();
        assertEq(
            totalClaimedAfter3, totalClaimedBefore3 + claimAmount3, "totalClaimed should increase after third DAO claim"
        );

        // Verify cumulative total
        assertEq(
            totalClaimedAfter3,
            claimAmount1 + claimAmount2 + claimAmount3,
            "totalClaimed should be cumulative sum of all DAO claims"
        );
    }

    function test_TotalClaimed_NotAffectedByPauseUnpause() public {
        // Record initial totalClaimed
        uint256 initialTotalClaimed = staking.totalClaimed();

        // Pause staking
        vm.prank(dao);
        staking.pauseStaking();
        uint256 totalClaimedAfterPause = staking.totalClaimed();
        assertEq(totalClaimedAfterPause, initialTotalClaimed, "totalClaimed should not change after pause");

        // Unpause staking
        vm.prank(dao);
        staking.unpauseStaking();
        uint256 totalClaimedAfterUnpause = staking.totalClaimed();
        assertEq(totalClaimedAfterUnpause, initialTotalClaimed, "totalClaimed should not change after unpause");
    }

    function test_TotalClaimed_NotAffectedByClaimPause() public {
        // Record initial totalClaimed
        uint256 initialTotalClaimed = staking.totalClaimed();

        // Pause claim for user
        vm.prank(deployer);
        staking.pauseClaim(user1);
        uint256 totalClaimedAfterPause = staking.totalClaimed();
        assertEq(totalClaimedAfterPause, initialTotalClaimed, "totalClaimed should not change after claim pause");

        // Unpause claim for user
        vm.prank(deployer);
        staking.unpauseClaim(user1);
        uint256 totalClaimedAfterUnpause = staking.totalClaimed();
        assertEq(totalClaimedAfterUnpause, initialTotalClaimed, "totalClaimed should not change after claim unpause");
    }

    function test_TotalClaimed_MaxDaoClaim() public {
        // Setup: get maximum available amount
        uint256 maxAmount = mockToken.balanceOf(address(staking));

        // Record totalClaimed before DAO claim
        uint256 totalClaimedBefore = staking.totalClaimed();

        // DAO claims maximum amount
        vm.prank(dao);
        staking.claimToDao(maxAmount);

        // Check that totalClaimed increased by maximum amount
        uint256 totalClaimedAfter = staking.totalClaimed();
        assertEq(
            totalClaimedAfter, totalClaimedBefore + maxAmount, "totalClaimed should increase by maximum claim amount"
        );
    }

    function test_TotalClaimed_AccurateDaoTracking() public {
        // Setup: multiple DAO claims with different amounts
        uint256[] memory claimAmounts = new uint256[](5);
        claimAmounts[0] = 100 ether;
        claimAmounts[1] = 250 ether;
        claimAmounts[2] = 500 ether;
        claimAmounts[3] = 750 ether;
        claimAmounts[4] = 1000 ether;

        uint256 expectedTotal = 0;

        for (uint256 i = 0; i < claimAmounts.length; i++) {
            uint256 totalClaimedBefore = staking.totalClaimed();
            expectedTotal += claimAmounts[i];

            vm.prank(dao);
            staking.claimToDao(claimAmounts[i]);

            uint256 totalClaimedAfter = staking.totalClaimed();
            assertEq(totalClaimedAfter, expectedTotal, "totalClaimed should be cumulative sum of all DAO claims");
        }
    }
}
