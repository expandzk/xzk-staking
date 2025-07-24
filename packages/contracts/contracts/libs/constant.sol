// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

library Constants {
    // Total reward amount (50 million tokens) of underlying token
    uint256 public constant ALL_REWARD = (50_000_000 * 1e18);

    // Total duration 3 years)
    uint256 public constant TOTAL_DURATION_SECONDS = 3 * 365 days;

    // Total factor
    uint256 public constant TOTAL_FACTOR = 58875190375432478;
}
