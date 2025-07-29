// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Sepolia addresses
address constant SEPOLIA_DAO_REGISTRY = address(0x23e230EBf23E02393d8F5d74863Dac478dF93f5f);
IERC20 constant SEPOLIA_XZK_TOKEN = IERC20(0x932161e47821c6F5AE69ef329aAC84be1E547e53);
IERC20 constant SEPOLIA_VXZK_TOKEN = IERC20(0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587);
address constant SEPOLIA_PAUSE_ADMIN = address(0x5aae320D3EF8f2bb79e4CE2059Ea725dD23c1bF4);

// Ethereum addresses
address constant ETHEREUM_DAO_REGISTRY = address(0xC7713f0eC0ddcc20d6E03eDF12d85f81d18b74FB);
IERC20 constant ETHEREUM_XZK_TOKEN = IERC20(0xe8fC52b1bb3a40fd8889C0f8f75879676310dDf0);
IERC20 constant ETHEREUM_VXZK_TOKEN = IERC20(0x16aFFA80C65Fd7003d40B24eDb96f77b38dDC96A);
address constant ETHEREUM_PAUSE_ADMIN = address(0xCbF665AabeA896b47814d5B23878591D7F893Ae7);

// Total factors
uint256 constant TOTAL_FACTOR_365 = 5500;
uint256 constant TOTAL_FACTOR_180 = 2700;
uint256 constant TOTAL_FACTOR_90 = 1300;
uint256 constant TOTAL_FACTOR_FLEXIBLE = 500;
uint256 constant XZK_RATIO = 60;
uint256 constant VXZK_RATIO = 40;

// Total factors
uint256 constant TOTAL_FACTOR_DEV_3 = 4;
uint256 constant TOTAL_FACTOR_DEV_2 = 3;
uint256 constant TOTAL_FACTOR_DEV_1 = 2;
uint256 constant TOTAL_FACTOR_DEV_FLEXIBLE = 1;
