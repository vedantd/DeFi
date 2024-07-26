// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Pair {
    address public factory;
    address public token0;
    address public token1;

    constructor(address _factory) {
        factory = _factory;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN");
        require(
            token0 == address(0) && token1 == address(0),
            "UniswapV2: ALREADY_INITIALIZED"
        );
        token0 = _token0;
        token1 = _token1;
    }
}
