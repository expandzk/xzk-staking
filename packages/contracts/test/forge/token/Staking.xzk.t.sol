// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {XzkStakingToken} from "../../../contracts/token/XzkStakingToken.sol";
import {MockToken} from "../../../contracts/mocks/MockToken.sol";
import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Concrete implementation for testing
contract TestXzkStakingToken is XzkStakingToken {
    constructor(IERC20 _mystikoToken, string memory _stakingTokenName, string memory _stakingTokenSymbol)
        XzkStakingToken(_mystikoToken, _stakingTokenName, _stakingTokenSymbol)
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
    TestXzkStakingToken public stakingToken;
    MockToken public underlyingToken;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    string public constant TOKEN_NAME = "Mystiko Staking Token";
    string public constant TOKEN_SYMBOL = "svXZK";
    uint8 public constant TOKEN_DECIMALS = 18;

    function setUp() public {
        underlyingToken = new MockToken();
        stakingToken = new TestXzkStakingToken(underlyingToken, TOKEN_NAME, TOKEN_SYMBOL);
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

    function testDelegateToZeroAddress() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        vm.prank(user1);
        stakingToken.delegate(address(0));

        assertEq(stakingToken.delegates(user1), address(0), "Delegation to zero address should be set");
        assertEq(stakingToken.getVotes(user1), 0, "Voting power should be zero when delegated to zero address");
    }

    function testDelegateMultipleTimes() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        vm.startPrank(user1);
        stakingToken.delegate(user2);
        assertEq(stakingToken.getVotes(user2), amount, "First delegation should work");

        stakingToken.delegate(user3);
        assertEq(stakingToken.getVotes(user2), 0, "Previous delegate should lose voting power");
        assertEq(stakingToken.getVotes(user3), amount, "New delegate should have voting power");
        vm.stopPrank();
    }

    // ============ Clock and Mode Tests ============

    function testClock() public {
        uint256 currentTime = block.timestamp;
        assertEq(stakingToken.clock(), currentTime, "Clock should return current timestamp");
    }

    function testClockMode() public view {
        assertEq(stakingToken.CLOCK_MODE(), "mode=timestamp", "Clock mode should be timestamp");
    }

    // ============ Edge Cases ============

    function testMintZeroAmount() public {
        stakingToken.mint(user1, 0);
        assertEq(stakingToken.balanceOf(user1), 0, "Minting zero should not change balance");
        assertEq(stakingToken.totalSupply(), 0, "Total supply should remain zero");
    }

    function testBurnZeroAmount() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);
        stakingToken.burn(user1, 0);
        assertEq(stakingToken.balanceOf(user1), amount, "Burning zero should not change balance");
        assertEq(stakingToken.totalSupply(), amount, "Total supply should remain unchanged");
    }

    function testBurnMoreThanBalance() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        vm.expectRevert();
        stakingToken.burn(user1, amount + 1);
    }

    function testBurnFromZeroAddress() public {
        vm.expectRevert();
        stakingToken.burn(address(0), 1000 * 1e18);
    }

    // ============ Integration Tests ============

    function testCompleteTokenLifecycle() public {
        uint256 amount = 1000 * 1e18;

        // 1. Mint tokens
        stakingToken.mint(user1, amount);
        assertEq(stakingToken.balanceOf(user1), amount, "Balance should match minted amount");

        // 2. Delegate voting power
        vm.prank(user1);
        stakingToken.delegate(user1);
        assertEq(stakingToken.getVotes(user1), amount, "Voting power should match balance");

        // 3. Mint more tokens
        stakingToken.mint(user1, amount);
        assertEq(stakingToken.balanceOf(user1), amount * 2, "Balance should double");
        assertEq(stakingToken.getVotes(user1), amount * 2, "Voting power should double");

        // 4. Burn some tokens
        stakingToken.burn(user1, amount);
        assertEq(stakingToken.balanceOf(user1), amount, "Balance should return to original");
        assertEq(stakingToken.getVotes(user1), amount, "Voting power should return to original");

        // 5. Change delegation
        vm.prank(user1);
        stakingToken.delegate(user2);
        assertEq(stakingToken.getVotes(user1), 0, "Original user should have no voting power");
        assertEq(stakingToken.getVotes(user2), amount, "New delegate should have voting power");
    }

    function testMultipleUsersDelegation() public {
        uint256 amount1 = 1000 * 1e18;
        uint256 amount2 = 2000 * 1e18;

        // Mint tokens to different users
        stakingToken.mint(user1, amount1);
        stakingToken.mint(user2, amount2);

        // Delegate to different addresses
        vm.prank(user1);
        stakingToken.delegate(user3);
        vm.prank(user2);
        stakingToken.delegate(user3);

        // User3 should have combined voting power
        assertEq(stakingToken.getVotes(user3), amount1 + amount2, "Delegate should have combined voting power");
        assertEq(stakingToken.getVotes(user1), 0, "User1 should have no voting power");
        assertEq(stakingToken.getVotes(user2), 0, "User2 should have no voting power");
    }
}
