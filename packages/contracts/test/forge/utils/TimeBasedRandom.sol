// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

library TimeBasedRandom {
    function getRandomUint256(Vm vm) internal view returns (uint256) {
        uint256 t = vm.envOr("FORGE_TEST_SYSTEM_TIME", block.timestamp);
        uint256 random = uint256(keccak256(abi.encodePacked(t)));
        return random;
    }
}
