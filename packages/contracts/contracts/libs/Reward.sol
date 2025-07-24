// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Constants} from "./constant.sol";

library RewardsLibrary {
    uint256 private constant SCALE = 1e18;
    uint256 private constant LAMBDA_DECAY = 20 * 1e9;

    function calcTotalReward(uint256 timePassed) internal pure returns (uint256) {
        require(timePassed < 10 * 365 days, "Reward: Invalid time passed");
        uint256 x = LAMBDA_DECAY * timePassed;
        uint256 expNeg = expTaylor(x);
        uint256 scaledExpVal = (SCALE * SCALE) / expNeg;
        uint256 raw = SCALE - scaledExpVal;
        uint256 total = (raw * Constants.TOTAL_FACTOR) / 1e9;
        return total;
    }

    // Taylor series approximation of e^x with fixed point arithmetic
    // exp(x) = 1 + x + x^2/2! + x^3/3! + ... + x^n/n!
    // where x is in fixed-point with 18 decimals
    function expTaylor(uint256 x) internal pure returns (uint256) {
        uint256 sum = SCALE; // start with 1.0
        uint256 term = SCALE; // current term = 1.0
        for (uint256 i = 1; i < 20; i++) {
            term = (term * x) / SCALE;
            term = term / i;
            sum += term;
        }

        return sum;
    }
}
