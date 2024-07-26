// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Dai.sol";

contract DaiTest is Test {
    Dai dai;

    function setUp() public {
        dai = new Dai(address(this));
    }

    function testMint() public {
        dai.mint(address(this), 1000 ether);
        assertEq(dai.balanceOf(address(this)), 1000 ether);
    }

    function testBurn() public {
        dai.mint(address(this), 1000 ether);
        dai.burn(500 ether);
        assertEq(dai.balanceOf(address(this)), 500 ether);
    }

    function testFailMintToZeroAddress() public {
        dai.mint(address(0), 1000 ether);
    }

    function testFailBurnMoreThanBalance() public {
        dai.mint(address(this), 1000 ether);
        dai.burn(1500 ether);
    }
}
