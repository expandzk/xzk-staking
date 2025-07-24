// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../../contracts/libs/constant.sol";
import "../../contracts/XzkStaking.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./utils/TimeBasedRandom.sol";

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
            10000, // total factor
            block.timestamp + 5 days // start time
        );
        vm.stopPrank();
    }

    function testRewardAtSpecificTime() public {
        vm.startPrank(deployer);
        uint256 startTime = staking.START_TIME();
        vm.warp(startTime);
        vm.roll(1);

        for (uint256 i = 1; i <= 40; i++) {
            uint256 timePassed = i * 30 days + startTime;
            uint256 reward = staking.totalRewardAt(timePassed);
            console.log("i", i, "reward", reward);
        }
    }
}
