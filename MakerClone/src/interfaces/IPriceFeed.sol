// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPriceFeed {
    function getLatestPrice(address token) external view returns (uint256);
}
