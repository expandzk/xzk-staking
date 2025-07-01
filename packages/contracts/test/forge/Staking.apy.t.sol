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
        vm.warp(startTime - 1 hours);
        vm.roll(10);
        uint256 totalReward = staking.totalRewardAt(block.timestamp + 365 days);
        uint256 apyValue = staking.apy(1e18);
        assertEq(apyValue, totalReward, "APY be to total reward");

        vm.expectRevert("No staked amount");
        staking.apy_staker();
    }

    function testApyAfterStakingDuration(uint256 amount) public {
        vm.startPrank(deployer);
        uint256 startTime = staking.START_TIME();
        vm.warp(startTime + 2 hours);
        vm.roll(10);
        uint256 totalBalance = mockToken.balanceOf(deployer);
        amount = bound(amount, 1, totalBalance);
        mockToken.approve(address(staking), amount);
        staking.stake(amount);
        assertEq(staking.totalSupply(), amount);
        assertEq(staking.totalStaked(), amount);
        assertEq(staking.totalUnstaked(), 0);
        vm.stopPrank();

        uint256 total_duration = staking.TOTAL_DURATION_SECONDS();
        vm.warp(startTime + total_duration + 1 seconds);
        vm.roll(10);

        uint256 apyValue = staking.apy(1e18);
        assertEq(apyValue, 0, "APY should be zero");

        uint256 apyValue2 = staking.apy(amount);
        assertEq(apyValue2, 0, "APY should be zero");
    }

    function testApyWithStakingTokenSupply(uint256 time_passed, uint256 amount) public {
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

        uint256 total_duration = staking.TOTAL_DURATION_SECONDS();
        time_passed = bound(time_passed, startTime + 1, startTime + total_duration);

        vm.warp(startTime + time_passed);
        vm.roll(10);

        uint256 totalReward = staking.totalRewardAt(block.timestamp + 365 days);
        uint256 apyValue_staker = staking.apy_staker();
        assertEq(apyValue_staker, (totalReward * 1e18) / totalBalance, "APY should match");

        uint256 amount1 = bound(amount, 1, totalBalance - 1);
        uint256 amount2 = amount1 + 1;
        uint256 apyValue1 = staking.apy(amount1);
        uint256 apyValue2 = staking.apy(amount2);
        assertGe(apyValue1, 0, "apy1 should be greater than 0");
        assertGe(apyValue2, 0, "apy2 should be greater than 0");

        uint256 apyValue3 = staking.apy(totalBalance);
        assertLt(apyValue3, apyValue_staker, "apy3 should be less than apy_staker");
    }
}
