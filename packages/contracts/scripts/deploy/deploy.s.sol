// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {XzkStaking} from "../../contracts/XzkStaking.sol";
import {console} from "forge-std/console.sol";
import {SEPOLIA_DAO_REGISTRY, SEPOLIA_PAUSE_ADMIN, SEPOLIA_XZK_TOKEN, SEPOLIA_VXZK_TOKEN} from "./const.sol";
import {ETHEREUM_DAO_REGISTRY, ETHEREUM_PAUSE_ADMIN, ETHEREUM_XZK_TOKEN, ETHEREUM_VXZK_TOKEN} from "./const.sol";
import {TOTAL_FACTOR_365, TOTAL_FACTOR_180, TOTAL_FACTOR_90, TOTAL_FACTOR_FLEXIBLE} from "./const.sol";

contract DeployStaking is Script {
    function run(bool isMainnet, uint256 startTime) public {
        address envSepoliasXZK365d = vm.envAddress("sepolia_sXZK_365d");
        address envSepoliasXZK180d = vm.envAddress("sepolia_sXZK_180d");
        address envSepoliasXZK90d = vm.envAddress("sepolia_sXZK_90d");
        address envSepoliasXZKFlex = vm.envAddress("sepolia_sXZK_Flex");
        address envSepoliasVXZK365d = vm.envAddress("sepolia_sVXZK_365d");
        address envSepoliasVXZK180d = vm.envAddress("sepolia_sVXZK_180d");
        address envSepoliasVXZK90d = vm.envAddress("sepolia_sVXZK_90d");
        address envSepoliasVXZKFlex = vm.envAddress("sepolia_sVXZK_Flex");
        address envEthereumXZK365d = vm.envAddress("ethereum_sXZK_365d");
        address envEthereumXZK180d = vm.envAddress("ethereum_sXZK_180d");
        address envEthereumXZK90d = vm.envAddress("ethereum_sXZK_90d");
        address envEthereumXZKFlex = vm.envAddress("ethereum_sXZK_Flex");
        address envEthereumVXZK365d = vm.envAddress("ethereum_sVXZK_365d");
        address envEthereumVXZK180d = vm.envAddress("ethereum_sVXZK_180d");
        address envEthereumVXZK90d = vm.envAddress("ethereum_sVXZK_90d");
        address envEthereumVXZKFlex = vm.envAddress("ethereum_sVXZK_Flex");

        console.log("=== Starting Mystiko Staking Deployment ===");
        console.log("Network:", isMainnet ? "Ethereum Mainnet" : "Sepolia Testnet");
        console.log("Start Time:", startTime);
        console.log("");

        vm.startBroadcast();

        if (isMainnet) {
            console.log("Deploying to Ethereum Mainnet...");
            console.log("");

            if (envEthereumXZK365d == address(0)) {
                XzkStaking sXZK365 = new XzkStaking(
                    ETHEREUM_DAO_REGISTRY,
                    ETHEREUM_PAUSE_ADMIN,
                    ETHEREUM_XZK_TOKEN,
                    "Mystiko Staking XZK 365 days",
                    "sXZK-365d",
                    365 days,
                    TOTAL_FACTOR_365,
                    startTime
                );
                console.log("ethereum_sXZK_365d=", address(sXZK365));
            }

            if (envEthereumXZK180d == address(0)) {
                XzkStaking sXZK180 = new XzkStaking(
                    ETHEREUM_DAO_REGISTRY,
                    ETHEREUM_PAUSE_ADMIN,
                    ETHEREUM_XZK_TOKEN,
                    "Mystiko Staking XZK 180 days",
                    "sXZK-180d",
                    180 days,
                    TOTAL_FACTOR_180,
                    startTime
                );
                console.log("ethereum_sXZK_180d=", address(sXZK180));
            }

            if (envEthereumXZK90d == address(0)) {
                XzkStaking sXZK90 = new XzkStaking(
                    ETHEREUM_DAO_REGISTRY,
                    ETHEREUM_PAUSE_ADMIN,
                    ETHEREUM_XZK_TOKEN,
                    "Mystiko Staking XZK 90 days",
                    "sXZK-90d",
                    90 days,
                    TOTAL_FACTOR_90,
                    startTime
                );
                console.log("ethereum_sXZK_90d=", address(sXZK90));
            }

            if (envEthereumXZKFlex == address(0)) {
                XzkStaking sXZKFlexible = new XzkStaking(
                    ETHEREUM_DAO_REGISTRY,
                    ETHEREUM_PAUSE_ADMIN,
                    ETHEREUM_XZK_TOKEN,
                    "Mystiko Staking XZK Flexible",
                    "sXZK-Flex",
                    0,
                    TOTAL_FACTOR_FLEXIBLE,
                    startTime
                );
                console.log("ethereum_sXZK_Flex=", address(sXZKFlexible));
            }

            if (envEthereumVXZK365d == address(0)) {
                XzkStaking sVXZK365 = new XzkStaking(
                    ETHEREUM_DAO_REGISTRY,
                    ETHEREUM_PAUSE_ADMIN,
                    ETHEREUM_VXZK_TOKEN,
                    "Mystiko Staking VXZK 365 days",
                    "sVXZK-365d",
                    365 days,
                    TOTAL_FACTOR_365,
                    startTime
                );
                console.log("ethereum-sVXZK-365d=", address(sVXZK365));
            }

            if (envEthereumVXZK180d == address(0)) {
                XzkStaking sVXZK180 = new XzkStaking(
                    ETHEREUM_DAO_REGISTRY,
                    ETHEREUM_PAUSE_ADMIN,
                    ETHEREUM_VXZK_TOKEN,
                    "Mystiko Staking VXZK 180 days",
                    "sVXZK-180d",
                    180 days,
                    TOTAL_FACTOR_180,
                    startTime
                );
                console.log("ethereum-sVXZK-180d=", address(sVXZK180));
            }

            if (envEthereumVXZK90d == address(0)) {
                XzkStaking sVXZK90 = new XzkStaking(
                    ETHEREUM_DAO_REGISTRY,
                    ETHEREUM_PAUSE_ADMIN,
                    ETHEREUM_VXZK_TOKEN,
                    "Mystiko Staking VXZK 90 days",
                    "sVXZK-90d",
                    90 days,
                    TOTAL_FACTOR_90,
                    startTime
                );
                console.log("ethereum-sVXZK-90d=", address(sVXZK90));
            }

            if (envEthereumVXZKFlex == address(0)) {
                XzkStaking sVXZKFlexible = new XzkStaking(
                    ETHEREUM_DAO_REGISTRY,
                    ETHEREUM_PAUSE_ADMIN,
                    ETHEREUM_VXZK_TOKEN,
                    "Mystiko Staking VXZK Flexible",
                    "sVXZK-Flex",
                    0,
                    TOTAL_FACTOR_FLEXIBLE,
                    startTime
                );
                console.log("ethereum-sVXZK-Flex=", address(sVXZKFlexible));
            }
        } else {
            console.log("Deploying to Sepolia Testnet...");
            console.log("");

            if (envSepoliasXZK365d == address(0)) {
                XzkStaking sXZK365 = new XzkStaking(
                    SEPOLIA_DAO_REGISTRY,
                    SEPOLIA_PAUSE_ADMIN,
                    SEPOLIA_XZK_TOKEN,
                    "Mystiko Staking XZK 365 days",
                    "sXZK-365d",
                    365 days,
                    TOTAL_FACTOR_365,
                    startTime
                );
                console.log("sepolia_sXZK_365d=", address(sXZK365));
            }

            if (envSepoliasXZK180d == address(0)) {
                XzkStaking sXZK180 = new XzkStaking(
                    SEPOLIA_DAO_REGISTRY,
                    SEPOLIA_PAUSE_ADMIN,
                    SEPOLIA_XZK_TOKEN,
                    "Mystiko Staking XZK 180 days",
                    "sXZK-180d",
                    180 days,
                    TOTAL_FACTOR_180,
                    startTime
                );
                console.log("sepolia_sXZK_180d=", address(sXZK180));
            }

            if (envSepoliasXZK90d == address(0)) {
                XzkStaking sXZK90 = new XzkStaking(
                    SEPOLIA_DAO_REGISTRY,
                    SEPOLIA_PAUSE_ADMIN,
                    SEPOLIA_XZK_TOKEN,
                    "Mystiko Staking XZK 90 days",
                    "sXZK-90d",
                    90 days,
                    TOTAL_FACTOR_90,
                    startTime
                );
                console.log("sepolia_sXZK_90d=", address(sXZK90));
            }

            if (envSepoliasXZKFlex == address(0)) {
                XzkStaking sXZKFlexible = new XzkStaking(
                    SEPOLIA_DAO_REGISTRY,
                    SEPOLIA_PAUSE_ADMIN,
                    SEPOLIA_XZK_TOKEN,
                    "Mystiko Staking XZK Flexible",
                    "sXZK-Flex",
                    0,
                    TOTAL_FACTOR_FLEXIBLE,
                    startTime
                );
                console.log("sepolia_sXZK_Flex=", address(sXZKFlexible));
            }

            if (envSepoliasVXZK365d == address(0)) {
                XzkStaking sVXZK365 = new XzkStaking(
                    SEPOLIA_DAO_REGISTRY,
                    SEPOLIA_PAUSE_ADMIN,
                    SEPOLIA_VXZK_TOKEN,
                    "Mystiko Staking VXZK 365 days",
                    "sVXZK-365d",
                    365 days,
                    TOTAL_FACTOR_365,
                    startTime
                );
                console.log("sepolia_sVXZK_365d=", address(sVXZK365));
            }

            if (envSepoliasVXZK180d == address(0)) {
                XzkStaking sVXZK180 = new XzkStaking(
                    SEPOLIA_DAO_REGISTRY,
                    SEPOLIA_PAUSE_ADMIN,
                    SEPOLIA_VXZK_TOKEN,
                    "Mystiko Staking VXZK 180 days",
                    "sVXZK-180d",
                    180 days,
                    TOTAL_FACTOR_180,
                    startTime
                );
                console.log("sepolia_sVXZK_180d=", address(sVXZK180));
            }

            if (envSepoliasVXZK90d == address(0)) {
                XzkStaking sVXZK90 = new XzkStaking(
                    SEPOLIA_DAO_REGISTRY,
                    SEPOLIA_PAUSE_ADMIN,
                    SEPOLIA_VXZK_TOKEN,
                    "Mystiko Staking VXZK 90 days",
                    "sVXZK-90d",
                    90 days,
                    TOTAL_FACTOR_90,
                    startTime
                );
                console.log("sepolia_sVXZK_90d=", address(sVXZK90));
            }

            if (envSepoliasVXZKFlex == address(0)) {
                XzkStaking sVXZKFlexible = new XzkStaking(
                    SEPOLIA_DAO_REGISTRY,
                    SEPOLIA_PAUSE_ADMIN,
                    SEPOLIA_VXZK_TOKEN,
                    "Mystiko Staking VXZK Flexible",
                    "sVXZK-Flex",
                    0,
                    TOTAL_FACTOR_FLEXIBLE,
                    startTime
                );
                console.log("sepolia_sVXZK_Flex=", address(sVXZKFlexible));
            }
        }

        vm.stopBroadcast();

        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("Network:", isMainnet ? "Ethereum Mainnet" : "Sepolia Testnet");
        console.log("Total contracts deployed: 8");
        console.log("XZK contracts: 4 (365d, 180d, 90d, Flexible)");
        console.log("VXZK contracts: 4 (365d, 180d, 90d, Flexible)");
        console.log("Deployment completed successfully!");
    }
}
