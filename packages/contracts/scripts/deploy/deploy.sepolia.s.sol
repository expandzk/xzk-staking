// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {XzkStaking} from "../../contracts/XzkStaking.sol";
import {console} from "forge-std/console.sol";
import {SEPOLIA_DAO_REGISTRY, SEPOLIA_PAUSE_ADMIN, SEPOLIA_XZK_TOKEN, SEPOLIA_VXZK_TOKEN} from "./const.sol";
import {ETHEREUM_DAO_REGISTRY, ETHEREUM_PAUSE_ADMIN, ETHEREUM_XZK_TOKEN, ETHEREUM_VXZK_TOKEN} from "./const.sol";
import {TOTAL_FACTOR_365, TOTAL_FACTOR_180, TOTAL_FACTOR_90, TOTAL_FACTOR_FLEXIBLE} from "./const.sol";
import {XZK_RATIO, VXZK_RATIO} from "./const.sol";

contract DeployStaking is Script {
    function run(uint256 startTime) public {
        address envSepoliasXZK365d = vm.envAddress("sepolia_sXZK_365d");
        address envSepoliasXZK180d = vm.envAddress("sepolia_sXZK_180d");
        address envSepoliasXZK90d = vm.envAddress("sepolia_sXZK_90d");
        address envSepoliasXZKFlex = vm.envAddress("sepolia_sXZK_Flex");
        address envSepoliasVXZK365d = vm.envAddress("sepolia_svXZK_365d");
        address envSepoliasVXZK180d = vm.envAddress("sepolia_svXZK_180d");
        address envSepoliasVXZK90d = vm.envAddress("sepolia_svXZK_90d");
        address envSepoliasVXZKFlex = vm.envAddress("sepolia_svXZK_Flex");

        console.log("=== Starting XZK Staking Deployment ===");
        console.log("Network:", "Sepolia Testnet");
        console.log("Start Time:", startTime);
        console.log("");

        vm.startBroadcast();

        if (envSepoliasXZK365d == address(0)) {
            XzkStaking sXZK365 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK 365 days",
                "sXZK-365d",
                365 days,
                (TOTAL_FACTOR_365 * XZK_RATIO) / 100,
                startTime
            );
            console.log("sepolia_sXZK_365d=", address(sXZK365));
        }

        if (envSepoliasXZK180d == address(0)) {
            XzkStaking sXZK180 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK 180 days",
                "sXZK-180d",
                180 days,
                (TOTAL_FACTOR_180 * XZK_RATIO) / 100,
                startTime
            );
            console.log("sepolia_sXZK_180d=", address(sXZK180));
        }

        if (envSepoliasXZK90d == address(0)) {
            XzkStaking sXZK90 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK 90 days",
                "sXZK-90d",
                90 days,
                (TOTAL_FACTOR_90 * XZK_RATIO) / 100,
                startTime
            );
            console.log("sepolia_sXZK_90d=", address(sXZK90));
        }

        if (envSepoliasXZKFlex == address(0)) {
            XzkStaking sXZKFlexible = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_XZK_TOKEN,
                "Staking XZK Flexible",
                "sXZK-Flex",
                0,
                (TOTAL_FACTOR_FLEXIBLE * XZK_RATIO) / 100,
                startTime
            );
            console.log("sepolia_sXZK_Flex=", address(sXZKFlexible));
        }

        if (envSepoliasVXZK365d == address(0)) {
            XzkStaking sVXZK365 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking vXZK 365 days",
                "svXZK-365d",
                365 days,
                (TOTAL_FACTOR_365 * VXZK_RATIO) / 100,
                startTime
            );
            console.log("sepolia_svXZK_365d=", address(sVXZK365));
        }

        if (envSepoliasVXZK180d == address(0)) {
            XzkStaking sVXZK180 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking vXZK 180 days",
                "svXZK-180d",
                180 days,
                (TOTAL_FACTOR_180 * VXZK_RATIO) / 100,
                startTime
            );
            console.log("sepolia_svXZK_180d=", address(sVXZK180));
        }

        if (envSepoliasVXZK90d == address(0)) {
            XzkStaking sVXZK90 = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking vXZK 90 days",
                "svXZK-90d",
                90 days,
                (TOTAL_FACTOR_90 * VXZK_RATIO) / 100,
                startTime
            );
            console.log("sepolia_svXZK_90d=", address(sVXZK90));
        }

        if (envSepoliasVXZKFlex == address(0)) {
            XzkStaking sVXZKFlexible = new XzkStaking(
                SEPOLIA_DAO_REGISTRY,
                SEPOLIA_PAUSE_ADMIN,
                SEPOLIA_VXZK_TOKEN,
                "Staking vXZK Flexible",
                "svXZK-Flex",
                0,
                (TOTAL_FACTOR_FLEXIBLE * VXZK_RATIO) / 100,
                startTime
            );
            console.log("sepolia_svXZK_Flex=", address(sVXZKFlexible));
        }

        vm.stopBroadcast();

        console.log("");
        console.log("Deployment completed successfully!");
    }
}
