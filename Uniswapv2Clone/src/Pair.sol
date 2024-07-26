// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/console.sol";

contract Pair is ERC20 {
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;

    constructor(address _factory) ERC20("Uniswap V2", "UNI-V2") {
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

    function _update(uint balance0, uint balance1) private {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
        emit Sync(reserve0, reserve1);
    }

    function mint(address to) external returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        console.log("Balance0:", balance0);
        console.log("Balance1:", balance1);
        console.log("Reserve0:", _reserve0);
        console.log("Reserve1:", _reserve1);

        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        console.log("Amount0:", amount0);
        console.log("Amount1:", amount1);

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            require(liquidity > 0, "UniswapV2: INSUFFICIENT_INITIAL_LIQUIDITY");
            _mint(address(1), MINIMUM_LIQUIDITY); // mint to a non-zero address
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply()) / _reserve0,
                (amount1 * totalSupply()) / _reserve1
            );
        }

        console.log("Liquidity:", liquidity);

        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1);
        return liquidity;
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Sync(uint112 reserve0, uint112 reserve1);
}
