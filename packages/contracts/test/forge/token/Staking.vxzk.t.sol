// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {XzkStakingToken} from "../../../contracts/token/XzkStakingToken.sol";
import {MockToken} from "../../../contracts/mocks/MockToken.sol";
import {MockVoteToken} from "../../../contracts/mocks/MockVoteToken.sol";
import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TestXzkStakingToken is XzkStakingToken {
    constructor(IERC20 _underlying, string memory _name, string memory _symbol)
        XzkStakingToken(_underlying, _name, _symbol)
    {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract XzkStakingTokenVXZKTest is Test {
    TestXzkStakingToken public stakingToken;
    MockVoteToken public voteToken;
    MockToken public underlyingToken;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    string public constant TOKEN_NAME = "Mystiko Staking Vote Token";
    string public constant TOKEN_SYMBOL = "svXZK";
    uint8 public constant TOKEN_DECIMALS = 18;

    function setUp() public {
        underlyingToken = new MockToken();
        voteToken = new MockVoteToken(underlyingToken);
        stakingToken = new TestXzkStakingToken(voteToken, TOKEN_NAME, TOKEN_SYMBOL);
    }

    function testConstructor() public view {
        assertEq(stakingToken.name(), TOKEN_NAME, "Token name should match");
        assertEq(stakingToken.symbol(), TOKEN_SYMBOL, "Token symbol should match");
        assertEq(stakingToken.decimals(), TOKEN_DECIMALS, "Token decimals should match");
        assertEq(address(stakingToken.UNDERLYING_TOKEN()), address(voteToken), "Underlying token should match");
    }

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

    function testVotingPower() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);
        vm.prank(user1);
        stakingToken.delegate(user1);
        assertEq(stakingToken.getVotes(user1), amount, "Voting power should equal balance");
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

    function testWrapUnwrapFlow() public {
        // user1 has underlyingToken
        uint256 baseAmount = 1000 * 1e18;
        underlyingToken.mint(user1, baseAmount);
        // user1 approve voteToken
        vm.prank(user1);
        underlyingToken.approve(address(voteToken), baseAmount);
        // user1 wrap underlyingToken to voteToken
        vm.prank(user1);
        voteToken.depositFor(user1, baseAmount);
        assertEq(voteToken.balanceOf(user1), baseAmount, "VoteToken balance should match wrapped amount");
        // user1 approve stakingToken
        vm.prank(user1);
        voteToken.approve(address(stakingToken), baseAmount);
        // user1 mint stakingToken
        stakingToken.mint(user1, baseAmount);
        assertEq(stakingToken.balanceOf(user1), baseAmount, "StakingToken balance should match minted amount");
        // user1 delegate
        vm.prank(user1);
        stakingToken.delegate(user1);
        assertEq(stakingToken.getVotes(user1), baseAmount, "Voting power should match after wrap and mint");
        // user1 burn stakingToken
        stakingToken.burn(user1, baseAmount);
        assertEq(stakingToken.balanceOf(user1), 0, "StakingToken balance should be zero after burn");
    }

    function testClock() public {
        uint256 currentTime = block.timestamp;
        assertEq(stakingToken.clock(), currentTime, "Clock should return current timestamp");
    }

    function testClockMode() public view {
        assertEq(stakingToken.CLOCK_MODE(), "mode=timestamp", "Clock mode should be timestamp");
    }

    function testDelegation() public {
        uint256 amount = 1000 * 1e18;
        stakingToken.mint(user1, amount);

        vm.prank(user1);
        stakingToken.delegate(user2);

        assertEq(stakingToken.delegates(user1), user2, "Delegation should be set");
        assertEq(stakingToken.getVotes(user2), amount, "Delegate should have voting power");
        assertEq(stakingToken.getVotes(user1), 0, "Delegator should have no voting power");
    }

    function testMultipleUsers() public {
        uint256 amount1 = 1000 * 1e18;
        uint256 amount2 = 2000 * 1e18;

        stakingToken.mint(user1, amount1);
        stakingToken.mint(user2, amount2);

        vm.prank(user1);
        stakingToken.delegate(user1);
        vm.prank(user2);
        stakingToken.delegate(user2);

        assertEq(stakingToken.getVotes(user1), amount1, "User1 should have correct voting power");
        assertEq(stakingToken.getVotes(user2), amount2, "User2 should have correct voting power");
        assertEq(stakingToken.totalSupply(), amount1 + amount2, "Total supply should match sum");
    }
}
