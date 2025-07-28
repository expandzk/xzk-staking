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
        address envEthereumXZK365d = vm.envAddress("ethereum_sXZK_365d");
        address envEthereumXZK180d = vm.envAddress("ethereum_sXZK_180d");
        address envEthereumXZK90d = vm.envAddress("ethereum_sXZK_90d");
        address envEthereumXZKFlex = vm.envAddress("ethereum_sXZK_Flex");
        address envEthereumVXZK365d = vm.envAddress("ethereum_sVXZK_365d");
        address envEthereumVXZK180d = vm.envAddress("ethereum_sVXZK_180d");
        address envEthereumVXZK90d = vm.envAddress("ethereum_sVXZK_90d");
        address envEthereumVXZKFlex = vm.envAddress("ethereum_sVXZK_Flex");

        console.log("=== Starting XZK Staking Deployment ===");
        console.log("Network:", "Ethereum Mainnet");
        console.log("Start Time:", startTime);
        console.log("");

        vm.startBroadcast();

        console.log("Deploying to Ethereum Mainnet...");
        console.log("");

        if (envEthereumXZK365d == address(0)) {
            XzkStaking sXZK365 = new XzkStaking(
                ETHEREUM_DAO_REGISTRY,
                ETHEREUM_PAUSE_ADMIN,
                ETHEREUM_XZK_TOKEN,
                "Staking XZK 365 days",
                "sXZK-365d",
                365 days,
                (TOTAL_FACTOR_365 * XZK_RATIO) / 100,
                startTime
            );
            console.log("ethereum_sXZK_365d=", address(sXZK365));
        }

        if (envEthereumXZK180d == address(0)) {
            XzkStaking sXZK180 = new XzkStaking(
                ETHEREUM_DAO_REGISTRY,
                ETHEREUM_PAUSE_ADMIN,
                ETHEREUM_XZK_TOKEN,
                "Staking XZK 180 days",
                "sXZK-180d",
                180 days,
                (TOTAL_FACTOR_180 * XZK_RATIO) / 100,
                startTime
            );
            console.log("ethereum_sXZK_180d=", address(sXZK180));
        }

        if (envEthereumXZK90d == address(0)) {
            XzkStaking sXZK90 = new XzkStaking(
                ETHEREUM_DAO_REGISTRY,
                ETHEREUM_PAUSE_ADMIN,
                ETHEREUM_XZK_TOKEN,
                "Staking XZK 90 days",
                "sXZK-90d",
                90 days,
                (TOTAL_FACTOR_90 * XZK_RATIO) / 100,
                startTime
            );
            console.log("ethereum_sXZK_90d=", address(sXZK90));
        }

        if (envEthereumXZKFlex == address(0)) {
            XzkStaking sXZKFlexible = new XzkStaking(
                ETHEREUM_DAO_REGISTRY,
                ETHEREUM_PAUSE_ADMIN,
                ETHEREUM_XZK_TOKEN,
                "Staking XZK Flexible",
                "sXZK-Flex",
                0,
                (TOTAL_FACTOR_FLEXIBLE * XZK_RATIO) / 100,
                startTime
            );
            console.log("ethereum_sXZK_Flex=", address(sXZKFlexible));
        }

        if (envEthereumVXZK365d == address(0)) {
            XzkStaking sVXZK365 = new XzkStaking(
                ETHEREUM_DAO_REGISTRY,
                ETHEREUM_PAUSE_ADMIN,
                ETHEREUM_VXZK_TOKEN,
                "Staking VXZK 365 days",
                "sVXZK-365d",
                365 days,
                (TOTAL_FACTOR_365 * VXZK_RATIO) / 100,
                startTime
            );
            console.log("ethereum-sVXZK-365d=", address(sVXZK365));
        }

        if (envEthereumVXZK180d == address(0)) {
            XzkStaking sVXZK180 = new XzkStaking(
                ETHEREUM_DAO_REGISTRY,
                ETHEREUM_PAUSE_ADMIN,
                ETHEREUM_VXZK_TOKEN,
                "Staking VXZK 180 days",
                "sVXZK-180d",
                180 days,
                (TOTAL_FACTOR_180 * VXZK_RATIO) / 100,
                startTime
            );
            console.log("ethereum-sVXZK-180d=", address(sVXZK180));
        }

        if (envEthereumVXZK90d == address(0)) {
            XzkStaking sVXZK90 = new XzkStaking(
                ETHEREUM_DAO_REGISTRY,
                ETHEREUM_PAUSE_ADMIN,
                ETHEREUM_VXZK_TOKEN,
                "Staking VXZK 90 days",
                "sVXZK-90d",
                90 days,
                (TOTAL_FACTOR_90 * VXZK_RATIO) / 100,
                startTime
            );
            console.log("ethereum-sVXZK-90d=", address(sVXZK90));
        }

        if (envEthereumVXZKFlex == address(0)) {
            XzkStaking sVXZKFlexible = new XzkStaking(
                ETHEREUM_DAO_REGISTRY,
                ETHEREUM_PAUSE_ADMIN,
                ETHEREUM_VXZK_TOKEN,
                "Staking VXZK Flexible",
                "sVXZK-Flex",
                0,
                (TOTAL_FACTOR_FLEXIBLE * VXZK_RATIO) / 100,
                startTime
            );
            console.log("ethereum-sVXZK-Flex=", address(sVXZKFlexible));
        }

        vm.stopBroadcast();

        console.log("");
        console.log("Deployment completed successfully!");
    }
}
