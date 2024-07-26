// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Pair {
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

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

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
}
