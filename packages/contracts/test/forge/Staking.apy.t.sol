// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/XzkStaking.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1_000_000_000 ether);
    }
}

contract StakingApyTest is Test {
    XzkStaking staking;
    MockToken mockToken;
    address deployer = makeAddr("deployer");
    address dao = makeAddr("dao");
    address pauseAdmin = makeAddr("pauseAdmin");

    function setUp() public {
        vm.startPrank(deployer);
        mockToken = new MockToken();
        staking = new XzkStaking(
            address(dao),
            pauseAdmin,
            mockToken,
            "Mystiko Staking Token Flexible",
            "sXZK-Flex",
            0, // flexible staking period
            100, // total factor
            block.timestamp + 1 days // start time
        );
        vm.stopPrank();
    }

    function testApyNoStaking() public {
        uint256 startTime = staking.START_TIME();
        uint256 totalReward = staking.totalRewardAt(block.timestamp + 365 days);
        vm.warp(startTime - 1 hours);
        vm.roll(10);
        uint256 apyValue = staking.apy(1e18);
        assertEq(apyValue, totalReward, "APY be to total reward");

        vm.expectRevert("No staked amount");
        staking.apy_staker();
    }

    function testApyWithStakingTokenSupply() public {
        vm.startPrank(deployer);
        uint256 startTime = staking.START_TIME();
        vm.warp(startTime - 2 hours);
        vm.roll(10);
        uint256 totalBalance = mockToken.balanceOf(deployer);
        mockToken.approve(address(staking), totalBalance);
        staking.stake(totalBalance);
        assertEq(staking.totalSupply(), totalBalance);
        assertEq(staking.totalStaked(), totalBalance);
        assertEq(staking.totalUnstaked(), 0);
        vm.stopPrank();

        uint256 apyValue_staker = staking.apy_staker();
        assertEq(apyValue_staker, 500000000000000, "APY should match");

        uint256 apyValue = staking.apy(1);
        assertEq(apyValue, 0, "APY should be zero");

        uint256 apyValue2 = staking.apy(1e18);
        assertEq(apyValue2, 499999999500000, "APY should match");

        uint256 apyValue3 = staking.apy(totalBalance);
        assertEq(apyValue3, 250000000000000, "APY should match");
    }
}
