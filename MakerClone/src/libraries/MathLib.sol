// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library MathLib {
    uint256 public constant PRECISION = 1e18;

    function calculateHealthFactor(
        uint256 totalDaiDebt,
        uint256 collateralValueInUsd,
        uint256 liquidationThreshold
    ) internal pure returns (uint256) {
        if (totalDaiDebt == 0) return type(uint256).max;

        // Convert liquidationThreshold to basis points (e.g., 150% -> 15000)
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd *
            liquidationThreshold *
            100) / 10000;

        return (collateralAdjustedForThreshold * PRECISION) / totalDaiDebt;
    }
}
