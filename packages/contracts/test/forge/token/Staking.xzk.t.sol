// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MystikoStakingToken} from "../../../contracts/token/MystikoStakingToken.sol";
import {MockToken} from "../../../contracts/mocks/MockToken.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Concrete implementation for testing
contract TestMystikoStakingToken is MystikoStakingToken {
    constructor(IERC20 _mystikoToken, string memory _stakingTokenName, string memory _stakingTokenSymbol)
        MystikoStakingToken(_mystikoToken, _stakingTokenName, _stakingTokenSymbol)
    {}

    // Expose internal functions for testing
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract MystikoStakingTokenXZKTest is Test {
    TestMystikoStakingToken public stakingToken;
    MockToken public underlyingToken;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    string public constant TOKEN_NAME = "Mystiko Staking Token";
    string public constant TOKEN_SYMBOL = "sVXZK";
    uint8 public constant TOKEN_DECIMALS = 18;

    function setUp() public {
        underlyingToken = new MockToken();
        stakingToken = new TestMystikoStakingToken(underlyingToken, TOKEN_NAME, TOKEN_SYMBOL);
    }

    // ============ Constructor Tests ============

    function testConstructor() public view {
        assertEq(stakingToken.name(), TOKEN_NAME, "Token name should match");
        assertEq(stakingToken.symbol(), TOKEN_SYMBOL, "Token symbol should match");
        assertEq(stakingToken.decimals(), TOKEN_DECIMALS, "Token decimals should match");
        assertEq(address(stakingToken.UNDERLYING_TOKEN()), address(underlyingToken), "Underlying token should match");
    }

    // ============ ERC20 Basic Functionality Tests ============

    function testMintAndBalance() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        assertEq(stakingToken.balanceOf(user1), amount, "Balance should match minted amount");
        assertEq(stakingToken.totalSupply(), amount, "Total supply should match minted amount");
    }

    function testBurn() public {
        uint256 mintAmount = 1000 * 1e18;
        uint256 burnAmount = 500 * 1e18;

        stakingToken.mint(user1, mintAmount);
        stakingToken.burn(user1, burnAmount);

        assertEq(stakingToken.balanceOf(user1), mintAmount - burnAmount, "Balance should be reduced after burn");
        assertEq(stakingToken.totalSupply(), mintAmount - burnAmount, "Total supply should be reduced after burn");
    }

    function testMultipleMints() public {
        uint256 amount1 = 1000 * 1e18;
        uint256 amount2 = 2000 * 1e18;

        stakingToken.mint(user1, amount1);
        stakingToken.mint(user2, amount2);

        assertEq(stakingToken.balanceOf(user1), amount1, "User1 balance should match");
        assertEq(stakingToken.balanceOf(user2), amount2, "User2 balance should match");
        assertEq(stakingToken.totalSupply(), amount1 + amount2, "Total supply should match sum");
    }

    // ============ Transfer Restriction Tests ============

    function testTransferDisabled() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        vm.expectRevert("Transfers are disabled for this token");
        stakingToken.transfer(user2, amount);
    }

    function testTransferFromDisabled() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        vm.expectRevert("Transfers are disabled for this token");
        stakingToken.transferFrom(user1, user2, amount);
    }

    function testTransferWithZeroAmount() public {
        vm.expectRevert("Transfers are disabled for this token");
        stakingToken.transfer(user2, 0);
    }

    function testTransferFromWithZeroAmount() public {
        vm.expectRevert("Transfers are disabled for this token");
        stakingToken.transferFrom(user1, user2, 0);
    }

    // ============ Voting Functionality Tests ============

    function testVotingPower() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);
        vm.prank(user1);
        stakingToken.delegate(user1);
        assertEq(stakingToken.getVotes(user1), amount, "Voting power should equal balance");
    }

    function testVotingPowerAfterMint() public {
        uint256 amount1 = 1000 * 1e18;
        uint256 amount2 = 2000 * 1e18;
        stakingToken.mint(user1, amount1);
        vm.prank(user1);
        stakingToken.delegate(user1);
        assertEq(stakingToken.getVotes(user1), amount1, "Initial voting power should match");
        stakingToken.mint(user1, amount2);
        assertEq(stakingToken.getVotes(user1), amount1 + amount2, "Voting power should increase after mint");
    }

    function testVotingPowerAfterBurn() public {
        uint256 mintAmount = 1000 * 1e18;
        uint256 burnAmount = 500 * 1e18;
        stakingToken.mint(user1, mintAmount);
        vm.prank(user1);
        stakingToken.delegate(user1);
        stakingToken.burn(user1, burnAmount);
        assertEq(stakingToken.getVotes(user1), mintAmount - burnAmount, "Voting power should decrease after burn");
    }

    function testTotalVotingPower() public {
        uint256 amount1 = 1000 * 1e18;
        uint256 amount2 = 2000 * 1e18;
        stakingToken.mint(user1, amount1);
        stakingToken.mint(user2, amount2);
        vm.prank(user1);
        stakingToken.delegate(user1);
        vm.prank(user2);
        stakingToken.delegate(user2);
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        uint256 pastTimestamp = block.timestamp - 1;
        assertEq(
            stakingToken.getPastTotalSupply(pastTimestamp),
            amount1 + amount2,
            "Total voting power should match total supply"
        );
    }

    function testPastVotes() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);
        vm.prank(user1);
        stakingToken.delegate(user1);
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        uint256 pastTimestamp = block.timestamp - 1;
        assertEq(
            stakingToken.getPastVotes(user1, pastTimestamp), amount, "Past votes should match balance at that time"
        );
    }

    // ============ Delegation Tests ============

    function testDelegate() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        vm.prank(user1);
        stakingToken.delegate(user2);

        assertEq(stakingToken.delegates(user1), user2, "Delegation should be set");
        assertEq(stakingToken.getVotes(user2), amount, "Delegate should have voting power");
        assertEq(stakingToken.getVotes(user1), 0, "Delegator should have no voting power");
    }

    function testDelegateToSelf() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        vm.prank(user1);
        stakingToken.delegate(user1);

        assertEq(stakingToken.delegates(user1), user1, "Self-delegation should be set");
        assertEq(stakingToken.getVotes(user1), amount, "Self-delegation should maintain voting power");
    }

    function testDelegateWithNoBalance() public {
        vm.prank(user1);
        stakingToken.delegate(user2);

        assertEq(stakingToken.delegates(user1), user2, "Delegation should be set even with no balance");
        assertEq(stakingToken.getVotes(user2), 0, "Delegate should have no voting power");
    }

    function testChangeDelegation() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        vm.startPrank(user1);
        stakingToken.delegate(user2);
        assertEq(stakingToken.getVotes(user2), amount, "First delegate should have voting power");

        stakingToken.delegate(user3);
        assertEq(stakingToken.getVotes(user2), 0, "Previous delegate should lose voting power");
        assertEq(stakingToken.getVotes(user3), amount, "New delegate should have voting power");
        vm.stopPrank();
    }

    // ============ Clock and EIP712 Tests ============

    function testClock() public {
        uint256 timestamp = block.timestamp;
        assertEq(stakingToken.clock(), timestamp, "Clock should return current timestamp");
    }

    function testClockMode() public view {
        assertEq(stakingToken.CLOCK_MODE(), "mode=timestamp", "Clock mode should be timestamp");
    }

    function testEIP712Domain() public view {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = stakingToken.eip712Domain();

        assertEq(name, TOKEN_NAME, "EIP712 name should match token name");
        assertEq(version, "1", "EIP712 version should be 1");
        assertEq(verifyingContract, address(stakingToken), "EIP712 verifying contract should be token address");
        assertEq(chainId, block.chainid, "EIP712 chainId should match current chain");
        assertEq(salt, bytes32(0), "EIP712 salt should be zero");
        assertEq(extensions.length, 0, "EIP712 extensions should be empty");
        assertEq(fields, hex"0f", "EIP712 fields should be 0x0f");
    }

    // ============ Edge Cases and Error Handling ============

    function testMintToZeroAddress() public {
        vm.expectRevert(); // ERC20 should revert on zero address mint
        stakingToken.mint(address(0), 1000 * 1e18);
    }

    function testBurnMoreThanBalance() public {
        uint256 mintAmount = 1000 * 1e18;
        uint256 burnAmount = 2000 * 1e18;

        stakingToken.mint(user1, mintAmount);
        vm.expectRevert(); // Should revert when burning more than balance
        stakingToken.burn(user1, burnAmount);
    }

    function testDelegateToZeroAddress() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);
        vm.prank(user1);
        stakingToken.delegate(address(0));
        assertEq(stakingToken.delegates(user1), address(0), "Delegation to zero address should be set");
        assertEq(stakingToken.getVotes(user1), 0, "Voting power should be zero after delegating to zero address");
    }

    // ============ Integration Tests ============

    function testCompleteStakingFlow() public {
        uint256 stakeAmount = 1000 * 1e18;
        stakingToken.mint(user1, stakeAmount);
        vm.prank(user1);
        stakingToken.delegate(user2);
        assertEq(stakingToken.balanceOf(user1), stakeAmount, "Balance should match staked amount");
        assertEq(stakingToken.getVotes(user2), stakeAmount, "Delegate should have voting power");
        stakingToken.burn(user1, stakeAmount);
        assertEq(stakingToken.balanceOf(user1), 0, "Balance should be zero after unstake");
        assertEq(stakingToken.getVotes(user2), 0, "Delegate should lose voting power after unstake");
        assertEq(stakingToken.totalSupply(), 0, "Total supply should be zero");
    }

    function testMultipleUsersStaking() public {
        uint256 amount1 = 1000 * 1e18;
        uint256 amount2 = 2000 * 1e18;
        uint256 amount3 = 3000 * 1e18;
        stakingToken.mint(user1, amount1);
        stakingToken.mint(user2, amount2);
        stakingToken.mint(user3, amount3);
        vm.prank(user1);
        stakingToken.delegate(user1);
        vm.prank(user2);
        stakingToken.delegate(user2);
        vm.prank(user3);
        stakingToken.delegate(user3);
        assertEq(stakingToken.balanceOf(user1), amount1, "User1 balance should match");
        assertEq(stakingToken.balanceOf(user2), amount2, "User2 balance should match");
        assertEq(stakingToken.balanceOf(user3), amount3, "User3 balance should match");
        assertEq(stakingToken.totalSupply(), amount1 + amount2 + amount3, "Total supply should match sum");
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        uint256 pastTimestamp = block.timestamp - 1;
        assertEq(
            stakingToken.getPastTotalSupply(pastTimestamp),
            amount1 + amount2 + amount3,
            "Total voting power should match total supply"
        );
    }
}
