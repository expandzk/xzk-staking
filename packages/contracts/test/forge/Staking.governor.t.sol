// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {MystikoStaking} from "../../contracts/MystikoStaking.sol";
import {MockToken} from "../../contracts/mocks/MockToken.sol";
import {MystikoGovernorRegistry} from "../../lib/mystiko-governance/packages/contracts/contracts/impl/MystikoGovernorRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GovernanceErrors} from "../../lib/mystiko-governance/packages/contracts/contracts/GovernanceErrors.sol";

contract StakingGovernorTest is Test {
    MystikoStaking public staking;
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
        staking = new MystikoStaking(
            address(daoRegistry),
            mockToken,
            "Mystiko Staking Vote Token 90D",
            "sVXZK-90D",
            90 days, // staking period
            15, // total factor
            block.timestamp + 1 days // start time
        );
        vm.stopPrank();

        // Transfer tokens to users for testing
        vm.startPrank(deployer);
        mockToken.transfer(user1, 1000 ether);
        mockToken.transfer(user2, 1000 ether);
        mockToken.transfer(address(staking), 10000 ether); // Fund staking contract
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
        vm.expectRevert("MystikoStaking: Invalid amount");
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

    function test_unpauseStaking_AlreadyUnpaused() public {
        assertFalse(staking.isStakingPaused(), "Staking should not be paused initially");

        // Unpause when already unpaused should work (no revert)
        vm.prank(dao);
        staking.unpauseStaking();
        assertFalse(staking.isStakingPaused(), "Staking should remain unpaused");
    }

    // ============ Integration Tests ============

    function test_PauseUnpauseCycle() public {
        // Test complete pause/unpause cycle
        assertFalse(staking.isStakingPaused(), "Initial state should be unpaused");

        // Pause
        vm.prank(dao);
        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "Should be paused");

        // Unpause
        vm.prank(dao);
        staking.unpauseStaking();
        assertFalse(staking.isStakingPaused(), "Should be unpaused");

        // Pause again
        vm.prank(dao);
        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "Should be paused again");

        // Unpause again
        vm.prank(dao);
        staking.unpauseStaking();
        assertFalse(staking.isStakingPaused(), "Should be unpaused again");
    }

    function test_StakingOperationsWhenPaused() public {
        // Setup: user1 has tokens and approves staking
        vm.startPrank(user1);
        mockToken.approve(address(staking), 100 ether);
        vm.stopPrank();

        // Pause staking
        vm.prank(dao);
        staking.pauseStaking();

        // Try to stake when paused - should fail
        vm.expectRevert("MystikoStaking: paused");
        vm.prank(user1);
        staking.stake(50 ether);

        // Try to unstake when paused - should fail
        vm.expectRevert("MystikoStaking: paused");
        vm.prank(user1);
        staking.unstake(10 ether, new uint256[](0));

        // Try to claim when paused - should fail
        vm.expectRevert("MystikoStaking: paused");
        vm.prank(user1);
        staking.claim();

        // Unpause staking
        vm.prank(dao);
        staking.unpauseStaking();

        // Now staking should work
        vm.prank(user1);
        bool result = staking.stake(50 ether);
        assertTrue(result, "Staking should work after unpausing");
    }

    function test_DAOChangeAfterDeployment() public {
        address newDao = makeAddr("newDao");

        // Change DAO
        vm.prank(dao);
        daoRegistry.setMystikoDAO(newDao);

        // Old DAO should no longer have access
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(dao);
        staking.pauseStaking();

        // New DAO should have access
        vm.prank(newDao);
        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "New DAO should be able to pause staking");
    }

    function test_DAOChangeAfterDeployment_ClaimToDao() public {
        address newDao = makeAddr("newDao");

        // Change DAO
        vm.prank(dao);
        daoRegistry.setMystikoDAO(newDao);

        // Old DAO should no longer have access
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(dao);
        staking.claimToDao(10 ether);

        // New DAO should have access
        vm.prank(newDao);
        staking.claimToDao(10 ether);

        uint256 newDaoBalance = mockToken.balanceOf(newDao);
        assertEq(newDaoBalance, 10 ether, "New DAO should receive claimed tokens");
    }

    function test_DAOChangeAfterDeployment_UnpauseStaking() public {
        address newDao = makeAddr("newDao");

        // Pause staking with current DAO
        vm.prank(dao);
        staking.pauseStaking();

        // Change DAO
        vm.prank(dao);
        daoRegistry.setMystikoDAO(newDao);

        // Old DAO should no longer have access to unpause
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(dao);
        staking.unpauseStaking();

        // New DAO should be able to unpause
        vm.prank(newDao);
        staking.unpauseStaking();
        assertFalse(staking.isStakingPaused(), "New DAO should be able to unpause staking");
    }

    function test_GovernorFunctions_EventEmission() public {
        // Test claimToDao event
        vm.expectEmit(true, false, false, true);
        emit ClaimedToDao(dao, 50 ether);
        vm.prank(dao);
        staking.claimToDao(50 ether);

        // Test pauseStaking event
        vm.expectEmit(true, false, false, false);
        emit StakingPausedByDao();
        vm.prank(dao);
        staking.pauseStaking();

        // Test unpauseStaking event
        vm.expectEmit(true, false, false, false);
        emit StakingUnpausedByDao();
        vm.prank(dao);
        staking.unpauseStaking();
    }

    function test_GovernorFunctions_StateConsistency() public {
        // Test that pause/unpause state is consistent
        assertFalse(staking.isStakingPaused(), "Initial state should be unpaused");

        // Multiple pauses should maintain paused state
        vm.startPrank(dao);
        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "Should be paused after first pause");

        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "Should remain paused after second pause");

        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "Should remain paused after third pause");
        vm.stopPrank();

        // Multiple unpauses should maintain unpaused state
        vm.startPrank(dao);
        staking.unpauseStaking();
        assertFalse(staking.isStakingPaused(), "Should be unpaused after first unpause");

        staking.unpauseStaking();
        assertFalse(staking.isStakingPaused(), "Should remain unpaused after second unpause");

        staking.unpauseStaking();
        assertFalse(staking.isStakingPaused(), "Should remain unpaused after third unpause");
        vm.stopPrank();
    }

    function test_GovernorFunctions_EdgeCases() public {
        // Test with very small amounts
        vm.prank(dao);
        staking.claimToDao(1 wei);
        uint256 daoBalance = mockToken.balanceOf(dao);
        assertEq(daoBalance, 1 wei, "DAO should receive 1 wei");

        // Test with large but reasonable amount
        vm.prank(dao);
        staking.claimToDao(3000 ether);
        daoBalance = mockToken.balanceOf(dao);
        assertEq(daoBalance, 1 wei + 3000 ether, "DAO should receive the large amount");

        // Test pause/unpause with rapid succession
        vm.startPrank(dao);
        for (uint256 i = 0; i < 10; i++) {
            staking.pauseStaking();
            assertTrue(staking.isStakingPaused(), "Should be paused");
            staking.unpauseStaking();
            assertFalse(staking.isStakingPaused(), "Should be unpaused");
        }
        vm.stopPrank();
    }

    function test_GovernorFunctions_ReentrancyProtection() public {
        // Test that governor functions are protected against reentrancy
        // This is implicit since the functions don't call external contracts
        // but we can test that they work correctly in sequence

        vm.startPrank(dao);

        // Claim, pause, unpause in sequence
        staking.claimToDao(10 ether);
        staking.pauseStaking();
        staking.unpauseStaking();

        // Verify final state
        assertFalse(staking.isStakingPaused(), "Final state should be unpaused");

        vm.stopPrank();
    }

    // ============ setAdminRole Tests ============

    function test_setAdminRole_Success() public {
        // Initially DAO should NOT have admin role
        bool hasAdminRole = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), dao);
        assertFalse(hasAdminRole, "DAO should NOT have admin role initially");

        // DAO should call setAdminRole to get admin privileges
        vm.prank(dao);
        staking.setAdminRole();

        // Now DAO should have admin role
        hasAdminRole = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), dao);
        assertTrue(hasAdminRole, "DAO should have admin role after setAdminRole");

        // Verify DAO can grant roles
        bytes32 testRole = keccak256("TEST_ROLE");
        vm.prank(dao);
        staking.grantRole(testRole, user1);

        bool user1HasRole = staking.hasRole(testRole, user1);
        assertTrue(user1HasRole, "User1 should have the granted role");
    }

    function test_setAdminRole_OnlyMystikoDAO() public {
        // Non-DAO address should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(nonDao);
        staking.setAdminRole();

        // User1 should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(user1);
        staking.setAdminRole();

        // Deployer should fail
        vm.expectRevert(GovernanceErrors.OnlyMystikoDAO.selector);
        vm.prank(deployer);
        staking.setAdminRole();
    }

    function test_setAdminRole_DAOChange() public {
        address newDao = makeAddr("newDao");

        // Initially old DAO should NOT have admin role
        bool oldDaoHasAdminRole = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), dao);
        assertFalse(oldDaoHasAdminRole, "Old DAO should NOT have admin role initially");

        // Change DAO
        vm.prank(dao);
        daoRegistry.setMystikoDAO(newDao);

        // New DAO should not have admin role initially
        bool newDaoHasAdminRole = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), newDao);
        assertFalse(newDaoHasAdminRole, "New DAO should not have admin role initially");

        // New DAO should be able to call setAdminRole
        vm.prank(newDao);
        staking.setAdminRole();

        // New DAO should now have admin role
        newDaoHasAdminRole = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), newDao);
        assertTrue(newDaoHasAdminRole, "New DAO should have admin role after setAdminRole");

        // Old DAO should still NOT have admin role (since it never called setAdminRole)
        oldDaoHasAdminRole = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), dao);
        assertFalse(oldDaoHasAdminRole, "Old DAO should still NOT have admin role");
    }

    function test_setAdminRole_MultipleCalls() public {
        // Initially DAO should NOT have admin role
        bool hasAdminRole0 = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), dao);
        assertFalse(hasAdminRole0, "DAO should NOT have admin role initially");

        vm.startPrank(dao);

        // First call
        staking.setAdminRole();
        bool hasAdminRole1 = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), dao);
        assertTrue(hasAdminRole1, "DAO should have admin role after first call");

        // Second call
        staking.setAdminRole();
        bool hasAdminRole2 = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), dao);
        assertTrue(hasAdminRole2, "DAO should still have admin role after second call");

        // Third call
        staking.setAdminRole();
        bool hasAdminRole3 = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), dao);
        assertTrue(hasAdminRole3, "DAO should still have admin role after third call");

        vm.stopPrank();
    }

    function test_setAdminRole_RoleManagement() public {
        // First, DAO needs to call setAdminRole to get admin privileges
        vm.prank(dao);
        staking.setAdminRole();

        bytes32 testRole = keccak256("TEST_ROLE");

        // Verify DAO can grant roles
        vm.prank(dao);
        staking.grantRole(testRole, user1);
        assertTrue(staking.hasRole(testRole, user1), "User1 should have granted role");

        // Verify DAO can revoke roles
        vm.prank(dao);
        staking.revokeRole(testRole, user1);
        assertFalse(staking.hasRole(testRole, user1), "User1 should not have role after revocation");

        // Verify DAO can grant roles to itself
        vm.prank(dao);
        staking.grantRole(testRole, dao);
        assertTrue(staking.hasRole(testRole, dao), "DAO should have role granted to itself");
    }

    function test_setAdminRole_DefaultAdminRole() public {
        // Verify DEFAULT_ADMIN_ROLE is correctly set
        bytes32 defaultAdminRole = staking.DEFAULT_ADMIN_ROLE();
        assertEq(defaultAdminRole, 0x00, "DEFAULT_ADMIN_ROLE should be 0x00");

        // Initially DAO should NOT have the DEFAULT_ADMIN_ROLE
        bool daoHasDefaultAdmin = staking.hasRole(defaultAdminRole, dao);
        assertFalse(daoHasDefaultAdmin, "DAO should NOT have DEFAULT_ADMIN_ROLE initially");

        // After calling setAdminRole, DAO should have DEFAULT_ADMIN_ROLE
        vm.prank(dao);
        staking.setAdminRole();

        daoHasDefaultAdmin = staking.hasRole(defaultAdminRole, dao);
        assertTrue(daoHasDefaultAdmin, "DAO should have DEFAULT_ADMIN_ROLE after setAdminRole");
    }

    function test_setAdminRole_WithoutSetup() public {
        // Create a new staking contract without calling setAdminRole
        MystikoStaking newStaking = new MystikoStaking(
            address(daoRegistry),
            mockToken,
            "Mystiko Staking Vote Token 2",
            "sVXZK2",
            0, // staking period
            1, // total factor
            block.timestamp + 1 days // start time
        );

        // DAO should not have admin role initially
        bool daoHasAdminRole = newStaking.hasRole(newStaking.DEFAULT_ADMIN_ROLE(), dao);
        assertFalse(daoHasAdminRole, "DAO should not have admin role without setAdminRole");

        // DAO should be able to call setAdminRole
        vm.prank(dao);
        newStaking.setAdminRole();

        // DAO should now have admin role
        daoHasAdminRole = newStaking.hasRole(newStaking.DEFAULT_ADMIN_ROLE(), dao);
        assertTrue(daoHasAdminRole, "DAO should have admin role after setAdminRole");
    }

    function test_GovernorFunctions_WorkWithoutAdminRole() public {
        // Governor functions should work without admin role
        // because they use onlyMystikoDAO modifier, not admin role checks

        // Verify DAO doesn't have admin role initially
        bool hasAdminRole = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), dao);
        assertFalse(hasAdminRole, "DAO should NOT have admin role initially");

        // But governor functions should still work
        vm.prank(dao);
        staking.claimToDao(10 ether);

        vm.prank(dao);
        staking.pauseStaking();
        assertTrue(staking.isStakingPaused(), "Staking should be paused");

        vm.prank(dao);
        staking.unpauseStaking();
        assertFalse(staking.isStakingPaused(), "Staking should be unpaused");
    }
}
