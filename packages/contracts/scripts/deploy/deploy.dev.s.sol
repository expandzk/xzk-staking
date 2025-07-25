// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {XzkStaking} from "../../contracts/XzkStaking.sol";
import {console} from "forge-std/console.sol";
import {SEPOLIA_DAO_REGISTRY, SEPOLIA_PAUSE_ADMIN, SEPOLIA_XZK_TOKEN, SEPOLIA_VXZK_TOKEN} from "./const.sol";
import {TOTAL_FACTOR_DEV_3, TOTAL_FACTOR_DEV_2, TOTAL_FACTOR_DEV_1, TOTAL_FACTOR_DEV_FLEXIBLE} from "./const.sol";

contract DeployStaking is Script {
    function run(uint256 startTime) public {
        address envSepoliasDevXZK3 = vm.envAddress("sepolia_dev_sXZK_3");
        address envSepoliasDevXZK2 = vm.envAddress("sepolia_dev_sXZK_2");
        address envSepoliasDevXZK1 = vm.envAddress("sepolia_dev_sXZK_1");
        address envSepoliasDevXZKFlex = vm.envAddress("sepolia_dev_sXZK_Flex");
        address envSepoliasDevVXZK3 = vm.envAddress("sepolia_dev_sVXZK_3");
        address envSepoliasDevVXZK2 = vm.envAddress("sepolia_dev_sVXZK_2");
        address envSepoliasDevVXZK1 = vm.envAddress("sepolia_dev_sVXZK_1");
        address envSepoliasDevVXZKFlex = vm.envAddress("sepolia_dev_sVXZK_Flex");

        console.log("=== Starting XZK Staking Deployment ===");
        console.log("Network:", "Sepolia Testnet Dev");
        console.log("");

        vm.startBroadcast();

        console.log("Deploying to Sepolia Testnet Dev...");
        console.log("");

        if (envSepoliasDevXZK3 == address(0)) {
            XzkStaking sXZK3 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK 3",
                "sXZK-3",
                1 hours,
                TOTAL_FACTOR_DEV_3,
                startTime
            );
            console.log("sepolia_dev_sXZK_3=", address(sXZK3));
        }

        if (envSepoliasDevXZK2 == address(0)) {
            XzkStaking sXZK2 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK 2",
                "sXZK-2",
                30 minutes,
                TOTAL_FACTOR_DEV_2,
                startTime
            );
            console.log("sepolia_dev_sXZK_2=", address(sXZK2));
        }

        if (envSepoliasDevXZK1 == address(0)) {
            XzkStaking sXZK1 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK 1",
                "sXZK-1",
                10 minutes,
                TOTAL_FACTOR_DEV_1,
                startTime
            );
            console.log("sepolia_dev_sXZK_1=", address(sXZK1));
        }

        if (envSepoliasDevXZKFlex == address(0)) {
            XzkStaking sXZKFlexible = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK Dev Flexible",
                "sXZK-Dev-Flex",
                0,
                TOTAL_FACTOR_DEV_FLEXIBLE,
                startTime
            );
            console.log("sepolia_dev_sXZK_Flex=", address(sXZKFlexible));
        }

        if (envSepoliasDevVXZK3 == address(0)) {
            XzkStaking sVXZK3 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking VXZK 3",
                "sVXZK-3",
                1 hours,
                TOTAL_FACTOR_DEV_3,
                startTime
            );
            console.log("sepolia_dev_sVXZK_3=", address(sVXZK3));
        }

        if (envSepoliasDevVXZK2 == address(0)) {
            XzkStaking sVXZK2 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking VXZK 2",
                "sVXZK-2",
                30 minutes,
                TOTAL_FACTOR_DEV_2,
                startTime
            );
            console.log("sepolia_dev_sVXZK_2=", address(sVXZK2));
        }

        if (envSepoliasDevVXZK1 == address(0)) {
            XzkStaking sVXZK1 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking VXZK 1",
                "sVXZK-1",
                10 minutes,
                TOTAL_FACTOR_DEV_1,
                startTime
            );
            console.log("sepolia_dev_sVXZK_1=", address(sVXZK1));
        }

        if (envSepoliasDevVXZKFlex == address(0)) {
            XzkStaking sVXZKFlexible = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking VXZK Dev Flexible",
                "sVXZK-Dev-Flex",
                0,
                TOTAL_FACTOR_DEV_FLEXIBLE,
                startTime
            );
            console.log("sepolia_dev_sVXZK_Flex=", address(sVXZKFlexible));
        }

        vm.stopBroadcast();

        console.log("");
        console.log("Deployment completed successfully!");
    }
}
