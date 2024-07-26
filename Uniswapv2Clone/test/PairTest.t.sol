// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Pair.sol";

contract PairTest is Test {
    Pair pair;
    address public factory;
    address public token0;
    address public token1;

    function setUp() public {
        factory = address(this);
        pair = new Pair(factory);
        token0 = address(new MockERC20("Token0", "TKN0", 18));
        token1 = address(new MockERC20("Token1", "TKN1", 18));
    }

    function testInitialize() public {
        pair.initialize(token0, token1);
        assertEq(pair.factory(), factory);
        assertEq(pair.token0(), token0);
        assertEq(pair.token1(), token1);
    }

    function testCannotInitializeTwice() public {
        pair.initialize(token0, token1);
        vm.expectRevert("UniswapV2: ALREADY_INITIALIZED");
        pair.initialize(token0, token1);
    }

    function testOnlyFactoryCanInitialize() public {
        vm.prank(address(0xdead));
        vm.expectRevert("UniswapV2: FORBIDDEN");
        pair.initialize(token0, token1);
    }
}

// Mock ERC20 token for testing
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}
