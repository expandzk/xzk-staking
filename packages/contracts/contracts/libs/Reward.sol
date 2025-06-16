// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

library RewardsLibrary {
    int256 private constant SCALE = 1e18;
    int256 private constant BASE = -10;
    int256 private constant MIN = 2;
    // Decay rate (in basis points, 0.0000003 = 300000000000/10^18)
    int256 private constant DECAY_RATE_SCALED = 300 * 1e9;

    function calcTotalRewardAtBlock(
        int256 blocksPassed,
        int256 totalFactor
    ) internal pure returns (uint256 totalRelease) {
        int256 x = -DECAY_RATE_SCALED * blocksPassed;
        int256 decayFactor = exp(x) - SCALE;
        int256 totalExp = BASE * decayFactor + MIN * blocksPassed * DECAY_RATE_SCALED;
        int256 total = (totalExp * totalFactor) / DECAY_RATE_SCALED;
        return uint256(total);
    }

    // Taylor series approximation of e^x with fixed point arithmetic
    // exp(x) = 1 + x + x^2/2! + x^3/3! + ... + x^n/n!
    // where x is in fixed-point with 18 decimals
    function exp(int256 x) internal pure returns (int256) {
        int256 sum = SCALE; // start with 1.0
        int256 term = SCALE; // current term = 1.0
        for (int256 i = 1; i < 10; i++) {
            term = (term * x) / SCALE;
            term = term / i;
            sum += term;
        }

        return sum;
    }
}
