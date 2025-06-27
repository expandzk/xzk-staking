// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {XzkStaking} from "../../contracts/XzkStaking.sol";
import {console} from "forge-std/console.sol";
import {SEPOLIA_DAO_REGISTRY, SEPOLIA_PAUSE_ADMIN, SEPOLIA_XZK_TOKEN, SEPOLIA_VXZK_TOKEN} from "./const.sol";
import {TOTAL_FACTOR_DEV_3, TOTAL_FACTOR_DEV_2, TOTAL_FACTOR_DEV_1, TOTAL_FACTOR_DEV_FLEXIBLE} from "./const.sol";

contract DeployStaking is Script {
    function run(uint256 startTime) public {
        address envSepoliasDevXZK3d = vm.envAddress("sepolia_dev_sXZK_3d");
        address envSepoliasDevXZK2d = vm.envAddress("sepolia_dev_sXZK_2d");
        address envSepoliasDevXZK1d = vm.envAddress("sepolia_dev_sXZK_1d");
        address envSepoliasDevXZKFlex = vm.envAddress("sepolia_dev_sXZK_Flex");
        address envSepoliasDevVXZK3d = vm.envAddress("sepolia_dev_sVXZK_3d");
        address envSepoliasDevVXZK2d = vm.envAddress("sepolia_dev_sVXZK_2d");
        address envSepoliasDevVXZK1d = vm.envAddress("sepolia_dev_sVXZK_1d");
        address envSepoliasDevVXZKFlex = vm.envAddress("sepolia_dev_sVXZK_Flex");

        console.log("=== Starting XZK Staking Deployment ===");
        console.log("Network:", "Sepolia Testnet Dev");
        console.log("");

        vm.startBroadcast();

        console.log("Deploying to Sepolia Testnet Dev...");
        console.log("");

        if (envSepoliasDevXZK3d == address(0)) {
            XzkStaking sXZK3d = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK 3 days",
                "sXZK-3d",
                3 days,
                TOTAL_FACTOR_DEV_3,
                startTime
            );
            console.log("sepolia_dev_sXZK_3d=", address(sXZK3d));
        }

        if (envSepoliasDevXZK2d == address(0)) {
            XzkStaking sXZK2d = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK 2 days",
                "sXZK-2d",
                2 days,
                TOTAL_FACTOR_DEV_2,
                startTime
            );
            console.log("sepolia_dev_sXZK_2d=", address(sXZK2d));
        }

        if (envSepoliasDevXZK1d == address(0)) {
            XzkStaking sXZK1d = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK 1 days",
                "sXZK-1d",
                1 days,
                TOTAL_FACTOR_DEV_1,
                startTime
            );
            console.log("sepolia_dev_sXZK_1d=", address(sXZK1d));
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

        if (envSepoliasDevVXZK3d == address(0)) {
            XzkStaking sVXZK3d = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking VXZK 3 days",
                "sVXZK-3d",
                3 days,
                TOTAL_FACTOR_DEV_3,
                startTime
            );
            console.log("sepolia_dev_sVXZK_3d=", address(sVXZK3d));
        }

        if (envSepoliasDevVXZK2d == address(0)) {
            XzkStaking sVXZK2d = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking VXZK 2 days",
                "sVXZK-2d",
                2 days,
                TOTAL_FACTOR_DEV_2,
                startTime
            );
            console.log("sepolia_dev_sVXZK_2d=", address(sVXZK2d));
        }

        if (envSepoliasDevVXZK1d == address(0)) {
            XzkStaking sVXZK1d = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking VXZK 1 days",
                "sVXZK-1d",
                1 days,
                TOTAL_FACTOR_DEV_1,
                startTime
            );
            console.log("sepolia_dev_sVXZK_1d=", address(sVXZK1d));
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
