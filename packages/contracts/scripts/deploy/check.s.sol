// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {XzkStaking} from "../../contracts/XzkStaking.sol";
import {TOTAL_FACTOR_365, TOTAL_FACTOR_180, TOTAL_FACTOR_90, TOTAL_FACTOR_FLEXIBLE} from "./const.sol";
import {SEPOLIA_DAO_REGISTRY, SEPOLIA_XZK_TOKEN, SEPOLIA_VXZK_TOKEN, SEPOLIA_PAUSE_ADMIN} from "./const.sol";
import {ETHEREUM_DAO_REGISTRY, ETHEREUM_XZK_TOKEN, ETHEREUM_VXZK_TOKEN, ETHEREUM_PAUSE_ADMIN} from "./const.sol";
import {TOTAL_FACTOR_DEV_3, TOTAL_FACTOR_DEV_2, TOTAL_FACTOR_DEV_1, TOTAL_FACTOR_DEV_FLEXIBLE} from "./const.sol";
import {XZK_RATIO, VXZK_RATIO} from "./const.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract CheckStaking is Script {
    function run(bool is_mainnet, bool is_dev, uint256 startTime) public view {
        console.log("Checking staking contracts...");
        if (is_mainnet) {
            check_ethereum_staking(startTime);
        } else if (is_dev) {
            check_sepolia_dev_staking(startTime);
        } else {
            check_sepolia_staking(startTime);
        }
    }

    function check_ethereum_staking(uint256 startTime) public view {
        console.log("Checking ethereum staking contracts...");
        check_ethereum_sXZK_365d_contract(startTime);
        check_ethereum_sVXZK_365d_contract(startTime);
        check_ethereum_sXZK_180d_contract(startTime);
        check_ethereum_sVXZK_180d_contract(startTime);
        check_ethereum_sXZK_90d_contract(startTime);
        check_ethereum_sVXZK_90d_contract(startTime);
        check_ethereum_sXZK_flexible_contract(startTime);
        check_ethereum_sVXZK_flexible_contract(startTime);
        console.log("check success");
    }

    function check_sepolia_dev_staking(uint256 startTime) public view {
        console.log("Checking sepolia dev staking contracts...");
        check_sepolia_dev_sXZK_3_contract(startTime);
        check_sepolia_dev_sVXZK_3_contract(startTime);
        check_sepolia_dev_sXZK_2_contract(startTime);
        check_sepolia_dev_sVXZK_2_contract(startTime);
        check_sepolia_dev_sXZK_1_contract(startTime);
        check_sepolia_dev_sVXZK_1_contract(startTime);
        check_sepolia_dev_sXZK_flexible_contract(startTime);
        check_sepolia_dev_sVXZK_flexible_contract(startTime);
        console.log("check success");
    }

    function check_sepolia_staking(uint256 startTime) public view {
        console.log("Checking sepolia staking contracts...");
        check_sepolia_sXZK_365d_contract(startTime);
        check_sepolia_sVXZK_365d_contract(startTime);
        check_sepolia_sXZK_180d_contract(startTime);
        check_sepolia_sVXZK_180d_contract(startTime);
        check_sepolia_sXZK_90d_contract(startTime);
        check_sepolia_sVXZK_90d_contract(startTime);
        check_sepolia_sXZK_flexible_contract(startTime);
        check_sepolia_sVXZK_flexible_contract(startTime);
        console.log("check success");
    }

    function check_ethereum_sXZK_365d_contract(uint256 startTime) public view {
        console.log("Checking ethereum staking contract: ethereum_sXZK_365d");
        address staking_contract = vm.envAddress("ethereum_sXZK_365d");
        if (staking_contract == address(0)) {
            console.log("ethereum_sXZK_365d is not deployed");
            return;
        }

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK 365 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-365d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_365d_contract(staking, true);
        check_ethereum_admin(staking);
        check_ethereum_xzk_token(staking);
    }

    function check_ethereum_sVXZK_365d_contract(uint256 startTime) public view {
        console.log("Checking ethereum staking contract: ethereum_svXZK_365d");
        address staking_contract = vm.envAddress("ethereum_svXZK_365d");
        if (staking_contract == address(0)) {
            console.log("ethereum_svXZK_365d is not deployed");
            return;
        }

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK 365 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-365d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_365d_contract(staking, false);
        check_ethereum_admin(staking);
        check_ethereum_vxzk_token(staking);
    }

    function check_ethereum_sXZK_180d_contract(uint256 startTime) public view {
        console.log("Checking ethereum staking contract: ethereum_sXZK_180d");
        address staking_contract = vm.envAddress("ethereum_sXZK_180d");
        if (staking_contract == address(0)) {
            console.log("ethereum_sXZK_180d is not deployed");
            return;
        }

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK 180 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-180d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_180d_contract(staking, true);
        check_ethereum_admin(staking);
        check_ethereum_xzk_token(staking);
    }

    function check_ethereum_sVXZK_180d_contract(uint256 startTime) public view {
        console.log("Checking ethereum staking contract: ethereum_svXZK_180d");
        address staking_contract = vm.envAddress("ethereum_svXZK_180d");
        if (staking_contract == address(0)) {
            console.log("ethereum_svXZK_180d is not deployed");
            return;
        }

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK 180 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-180d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_180d_contract(staking, false);
        check_ethereum_admin(staking);
        check_ethereum_vxzk_token(staking);
    }

    function check_ethereum_sXZK_90d_contract(uint256 startTime) public view {
        console.log("Checking ethereum staking contract: ethereum_sXZK_90d");
        address staking_contract = vm.envAddress("ethereum_sXZK_90d");
        if (staking_contract == address(0)) {
            console.log("ethereum_sXZK_90d is not deployed");
            return;
        }

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK 90 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-90d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_90d_contract(staking, true);
        check_ethereum_admin(staking);
        check_ethereum_xzk_token(staking);
    }

    function check_ethereum_sVXZK_90d_contract(uint256 startTime) public view {
        console.log("Checking ethereum staking contract: ethereum_svXZK_90d");
        address staking_contract = vm.envAddress("ethereum_svXZK_90d");
        if (staking_contract == address(0)) {
            console.log("ethereum_svXZK_90d is not deployed");
            return;
        }

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK 90 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-90d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_90d_contract(staking, false);
        check_ethereum_admin(staking);
        check_ethereum_vxzk_token(staking);
    }

    function check_ethereum_sXZK_flexible_contract(uint256 startTime) public view {
        console.log("Checking ethereum staking contract: ethereum_sXZK_Flex");
        address staking_contract = vm.envAddress("ethereum_sXZK_Flex");
        if (staking_contract == address(0)) {
            console.log("ethereum_sXZK_Flex is not deployed");
            return;
        }

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK Flexible")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-Flex")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_flexible_contract(staking, false, true);
        check_ethereum_admin(staking);
        check_ethereum_xzk_token(staking);
    }

    function check_ethereum_sVXZK_flexible_contract(uint256 startTime) public view {
        console.log("Checking ethereum staking contract: ethereum_svXZK_Flex");
        address staking_contract = vm.envAddress("ethereum_svXZK_Flex");
        if (staking_contract == address(0)) {
            console.log("ethereum_sVXZK_flexible is not deployed");
            return;
        }

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK Flexible")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-Flex")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_flexible_contract(staking, false, false);
        check_ethereum_admin(staking);
        check_ethereum_vxzk_token(staking);
    }

    function check_sepolia_sXZK_365d_contract(uint256 startTime) public view {
        console.log("Checking sepolia staking contract: sepolia_sXZK_365d");
        address staking_contract = vm.envAddress("sepolia_sXZK_365d");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK 365 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-365d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_365d_contract(staking, true);
        check_sepolia_admin(staking);
        check_sepolia_xzk_token(staking);
    }

    function check_sepolia_sVXZK_365d_contract(uint256 startTime) public view {
        console.log("Checking sepolia staking contract: sepolia_svXZK_365d");
        address staking_contract = vm.envAddress("sepolia_svXZK_365d");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK 365 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-365d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_365d_contract(staking, false);
        check_sepolia_admin(staking);
        check_sepolia_vxzk_token(staking);
    }

    function check_sepolia_sXZK_180d_contract(uint256 startTime) public view {
        console.log("Checking sepolia staking contract: sepolia_sXZK_180d");
        address staking_contract = vm.envAddress("sepolia_sXZK_180d");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK 180 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-180d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_180d_contract(staking, true);
        check_sepolia_admin(staking);
        check_sepolia_xzk_token(staking);
    }

    function check_sepolia_sVXZK_180d_contract(uint256 startTime) public view {
        console.log("Checking sepolia staking contract: sepolia_svXZK_180d");
        address staking_contract = vm.envAddress("sepolia_svXZK_180d");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK 180 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-180d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_180d_contract(staking, false);
        check_sepolia_admin(staking);
        check_sepolia_vxzk_token(staking);
    }

    function check_sepolia_sXZK_90d_contract(uint256 startTime) public view {
        console.log("Checking sepolia staking contract: sepolia_sXZK_90d");
        address staking_contract = vm.envAddress("sepolia_sXZK_90d");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK 90 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-90d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_90d_contract(staking, true);
        check_sepolia_admin(staking);
        check_sepolia_xzk_token(staking);
    }

    function check_sepolia_sVXZK_90d_contract(uint256 startTime) public view {
        console.log("Checking sepolia staking contract: sepolia_svXZK_90d");
        address staking_contract = vm.envAddress("sepolia_svXZK_90d");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK 90 days")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-90d")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_90d_contract(staking, false);
        check_sepolia_admin(staking);
        check_sepolia_vxzk_token(staking);
    }

    function check_sepolia_sXZK_flexible_contract(uint256 startTime) public view {
        console.log("Checking sepolia staking contract: sepolia_sXZK_Flex");
        address staking_contract = vm.envAddress("sepolia_sXZK_Flex");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK Flexible")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-Flex")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_flexible_contract(staking, false, true);
        check_sepolia_admin(staking);
        check_sepolia_xzk_token(staking);
    }

    function check_sepolia_sVXZK_flexible_contract(uint256 startTime) public view {
        console.log("Checking sepolia staking contract: sepolia_svXZK_Flex");
        address staking_contract = vm.envAddress("sepolia_svXZK_Flex");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK Flexible")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-Flex")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_flexible_contract(staking, false, false);
        check_sepolia_admin(staking);
        check_sepolia_vxzk_token(staking);
    }

    function check_sepolia_dev_sXZK_3_contract(uint256 startTime) public view {
        console.log("Checking sepolia dev staking contract: sepolia_dev_sXZK_3");
        address staking_contract = vm.envAddress("sepolia_dev_sXZK_3");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK 3")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-3")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_3_contract(staking);
        check_sepolia_admin(staking);
        check_sepolia_xzk_token(staking);
    }

    function check_sepolia_dev_sVXZK_3_contract(uint256 startTime) public view {
        console.log("Checking sepolia dev staking contract: sepolia_dev_svXZK_3");
        address staking_contract = vm.envAddress("sepolia_dev_svXZK_3");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK 3")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-3")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_3_contract(staking);
        check_sepolia_admin(staking);
        check_sepolia_vxzk_token(staking);
    }

    function check_sepolia_dev_sXZK_2_contract(uint256 startTime) public view {
        console.log("Checking sepolia dev staking contract: sepolia_dev_sXZK_2");
        address staking_contract = vm.envAddress("sepolia_dev_sXZK_2");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK 2")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-2")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_2_contract(staking);
        check_sepolia_admin(staking);
        check_sepolia_xzk_token(staking);
    }

    function check_sepolia_dev_sVXZK_2_contract(uint256 startTime) public view {
        console.log("Checking sepolia dev staking contract: sepolia_dev_svXZK_2");
        address staking_contract = vm.envAddress("sepolia_dev_svXZK_2");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK 2")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-2")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_2_contract(staking);
        check_sepolia_admin(staking);
        check_sepolia_vxzk_token(staking);
    }

    function check_sepolia_dev_sXZK_1_contract(uint256 startTime) public view {
        console.log("Checking sepolia dev staking contract: sepolia_dev_sXZK_1");
        address staking_contract = vm.envAddress("sepolia_dev_sXZK_1");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK 1")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-1")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_1_contract(staking);
        check_sepolia_admin(staking);
        check_sepolia_xzk_token(staking);
    }

    function check_sepolia_dev_sVXZK_1_contract(uint256 startTime) public view {
        console.log("Checking sepolia dev staking contract: sepolia_dev_svXZK_1");
        address staking_contract = vm.envAddress("sepolia_dev_svXZK_1");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK 1")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-1")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_1_contract(staking);
        check_sepolia_admin(staking);
        check_sepolia_vxzk_token(staking);
    }

    function check_sepolia_dev_sXZK_flexible_contract(uint256 startTime) public view {
        console.log("Checking sepolia dev staking contract: sepolia_dev_sXZK_Flex");
        address staking_contract = vm.envAddress("sepolia_dev_sXZK_Flex");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking XZK Dev Flexible")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("sXZK-Dev-Flex")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_flexible_contract(staking, true, true);
        check_sepolia_admin(staking);
        check_sepolia_xzk_token(staking);
    }

    function check_sepolia_dev_sVXZK_flexible_contract(uint256 startTime) public view {
        console.log("Checking sepolia dev staking contract: sepolia_dev_svXZK_Flex");
        address staking_contract = vm.envAddress("sepolia_dev_svXZK_Flex");
        assert(staking_contract != address(0));

        XzkStaking staking = XzkStaking(staking_contract);
        string memory name = staking.name();
        assert(keccak256(bytes(name)) == keccak256(bytes("Staking vXZK Dev Flexible")));

        string memory symbol = staking.symbol();
        assert(keccak256(bytes(symbol)) == keccak256(bytes("svXZK-Dev-Flex")));

        uint256 startTimestamp = staking.START_TIME();
        assert(startTimestamp == startTime);

        check_flexible_contract(staking, true, false);
        check_sepolia_admin(staking);
        check_sepolia_vxzk_token(staking);
    }

    function check_365d_contract(XzkStaking staking, bool is_xzk) public view {
        uint256 totalFactor = staking.TOTAL_FACTOR();
        if (is_xzk) {
            assert(totalFactor == (TOTAL_FACTOR_365 * XZK_RATIO) / 100);
        } else {
            assert(totalFactor == (TOTAL_FACTOR_365 * VXZK_RATIO) / 100);
        }

        uint256 period = staking.STAKING_PERIOD_SECONDS();
        assert(period == 365 days);

        check_staking_contract(staking, false);
    }

    function check_180d_contract(XzkStaking staking, bool is_xzk) public view {
        uint256 totalFactor = staking.TOTAL_FACTOR();
        if (is_xzk) {
            assert(totalFactor == (TOTAL_FACTOR_180 * XZK_RATIO) / 100);
        } else {
            assert(totalFactor == (TOTAL_FACTOR_180 * VXZK_RATIO) / 100);
        }

        uint256 period = staking.STAKING_PERIOD_SECONDS();
        assert(period == 180 days);

        check_staking_contract(staking, false);
    }

    function check_90d_contract(XzkStaking staking, bool is_xzk) public view {
        uint256 totalFactor = staking.TOTAL_FACTOR();
        if (is_xzk) {
            assert(totalFactor == (TOTAL_FACTOR_90 * XZK_RATIO) / 100);
        } else {
            assert(totalFactor == (TOTAL_FACTOR_90 * VXZK_RATIO) / 100);
        }

        uint256 period = staking.STAKING_PERIOD_SECONDS();
        assert(period == 90 days);

        check_staking_contract(staking, false);
    }

    function check_3_contract(XzkStaking staking) public view {
        uint256 totalFactor = staking.TOTAL_FACTOR();
        assert(totalFactor == TOTAL_FACTOR_DEV_3);

        uint256 period = staking.STAKING_PERIOD_SECONDS();
        assert(period == 3600);

        check_staking_contract(staking, true);
    }

    function check_2_contract(XzkStaking staking) public view {
        uint256 totalFactor = staking.TOTAL_FACTOR();
        assert(totalFactor == TOTAL_FACTOR_DEV_2);

        uint256 period = staking.STAKING_PERIOD_SECONDS();
        assert(period == 1800);

        check_staking_contract(staking, true);
    }

    function check_1_contract(XzkStaking staking) public view {
        uint256 totalFactor = staking.TOTAL_FACTOR();
        assert(totalFactor == TOTAL_FACTOR_DEV_1);

        uint256 period = staking.STAKING_PERIOD_SECONDS();
        assert(period == 600);

        check_staking_contract(staking, true);
    }

    function check_flexible_contract(XzkStaking staking, bool is_dev, bool is_xzk) public view {
        uint256 totalFactor = staking.TOTAL_FACTOR();
        if (is_dev) {
            assert(totalFactor == TOTAL_FACTOR_DEV_FLEXIBLE);
        } else {
            if (is_xzk) {
                assert(totalFactor == (TOTAL_FACTOR_FLEXIBLE * XZK_RATIO) / 100);
            } else {
                assert(totalFactor == (TOTAL_FACTOR_FLEXIBLE * VXZK_RATIO) / 100);
            }
        }

        uint256 period = staking.STAKING_PERIOD_SECONDS();
        assert(period == 0);

        uint256 totalReward = staking.TOTAL_REWARD();
        assert(totalReward == (staking.allReward() * totalFactor) / staking.ALL_SHARES());

        check_staking_contract(staking, is_dev);
    }

    function check_staking_contract(XzkStaking staking, bool is_dev) public view {
        uint256 totalDuration = staking.totalDurationSeconds();
        if (is_dev) {
            assert(totalDuration == 4 hours);
        } else {
            assert(totalDuration == 3 * 365 days);
        }

        uint256 totalShares = staking.ALL_SHARES();
        assert(totalShares == 10000);

        uint256 totalStaked = staking.totalStaked();
        assert(totalStaked == 0);

        uint256 totalUnstaked = staking.totalUnstaked();
        assert(totalUnstaked == 0);

        uint256 claimDelay = staking.CLAIM_DELAY_SECONDS();
        if (is_dev) {
            assert(claimDelay == 10 minutes);
        } else {
            assert(claimDelay == 1 days);
        }

        uint256 startDelay = staking.START_DELAY_SECONDS();
        if (is_dev) {
            assert(startDelay == 10 minutes);
        } else {
            assert(startDelay == 5 days);
        }

        bool isPaused = staking.isStakingPaused();
        assert(isPaused == false);

        uint256 totalSupply = staking.totalSupply();
        assert(totalSupply == 0);
    }

    function check_ethereum_admin(XzkStaking staking) public view {
        bool hasPauseAdmin = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), ETHEREUM_PAUSE_ADMIN);
        assert(hasPauseAdmin == true);

        address daoRegistry = address(staking.daoRegistry());
        assert(daoRegistry == ETHEREUM_DAO_REGISTRY);
    }

    function check_sepolia_admin(XzkStaking staking) public view {
        bool hasPauseAdmin = staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), SEPOLIA_PAUSE_ADMIN);
        assert(hasPauseAdmin == true);

        address daoRegistry = address(staking.daoRegistry());
        assert(daoRegistry == SEPOLIA_DAO_REGISTRY);
    }

    function check_ethereum_xzk_token(XzkStaking staking) public view {
        IERC20 xzkToken = staking.UNDERLYING_TOKEN();
        assert(xzkToken == ETHEREUM_XZK_TOKEN);
    }

    function check_sepolia_xzk_token(XzkStaking staking) public view {
        IERC20 xzkToken = staking.UNDERLYING_TOKEN();
        assert(xzkToken == SEPOLIA_XZK_TOKEN);
    }

    function check_ethereum_vxzk_token(XzkStaking staking) public view {
        IERC20 vxzkToken = IERC20(staking.UNDERLYING_TOKEN());
        assert(vxzkToken == ETHEREUM_VXZK_TOKEN);
    }

    function check_sepolia_vxzk_token(XzkStaking staking) public view {
        IERC20 vxzkToken = IERC20(staking.UNDERLYING_TOKEN());
        assert(vxzkToken == SEPOLIA_VXZK_TOKEN);
    }
}
