// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IPriceFeed} from "./interfaces/IPriceFeed.sol";

contract MockPriceFeed is IPriceFeed {
    uint256 private price;

    constructor(uint256 _initialPrice) {
        price = _initialPrice;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function getLatestPrice(address) external view override returns (uint256) {
        return price;
    }
}
