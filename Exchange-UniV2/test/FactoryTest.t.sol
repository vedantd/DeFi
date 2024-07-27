// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Factory.sol";
import "../src/Pair.sol";

contract FactoryTest is Test {
    Factory public factory;
    address public feeToSetter;
    address public token0;
    address public token1;
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function setUp() public {
        feeToSetter = address(this);
        factory = new Factory(feeToSetter);
        token0 = address(new MockERC20("Token0", "TKN0", 18));
        token1 = address(new MockERC20("Token1", "TKN1", 18));
    }

    function testCreatePair() public {
        address expectedPair = pairFor(
            address(factory),
            address(token0),
            address(token1)
        );

        vm.expectEmit(true, true, true, true);
        emit PairCreated(address(token0), address(token1), expectedPair, 1);

        address pair = factory.createPair(token0, token1);

        assertEq(
            pair,
            expectedPair,
            "Created pair address does not match expected address"
        );
        assertEq(factory.allPairsLength(), 1);
        assertEq(factory.getPair(token0, token1), pair);
        assertEq(factory.getPair(token1, token0), pair);
        assertEq(factory.allPairs(0), pair);
    }

    // Helper function to calculate the expected pair address
    function pairFor(
        address factoryAddress,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token3, address token4) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factoryAddress,
                            keccak256(abi.encodePacked(token3, token4)),
                            keccak256(
                                abi.encodePacked(
                                    type(Pair).creationCode,
                                    abi.encode(factoryAddress)
                                )
                            )
                        )
                    )
                )
            )
        );
    }

    function testCreatePairReversed() public {
        address pair = factory.createPair(token1, token0);
        assertEq(factory.allPairsLength(), 1);
        assertEq(factory.getPair(token0, token1), pair);
        assertEq(factory.getPair(token1, token0), pair);
    }

    function testCannotCreatePairWithIdenticalTokens() public {
        vm.expectRevert("Factory: IDENTICAL_ADDRESSES");
        factory.createPair(token0, token0);
    }

    function testCannotCreatePairWithZeroAddress() public {
        vm.expectRevert("Factory: ZERO_ADDRESS");
        factory.createPair(token0, address(0));
    }

    function testCannotCreateExistingPair() public {
        factory.createPair(token0, token1);
        vm.expectRevert("Factory: PAIR_EXISTS");
        factory.createPair(token0, token1);
    }

    function testSetFeeTo() public {
        address newFeeTo = address(0x123);
        factory.setFeeTo(newFeeTo);
        assertEq(factory.feeTo(), newFeeTo);
    }

    function testCannotSetFeeToUnauthorized() public {
        address unauthorized = address(0x456);
        vm.prank(unauthorized);
        vm.expectRevert("Factory: FORBIDDEN");
        factory.setFeeTo(unauthorized);
    }

    function testSetFeeToSetter() public {
        address newFeeToSetter = address(0x789);
        factory.setFeeToSetter(newFeeToSetter);
        assertEq(factory.feeToSetter(), newFeeToSetter);
    }

    function testCannotSetFeeToSetterUnauthorized() public {
        address unauthorized = address(0xabc);
        vm.prank(unauthorized);
        vm.expectRevert("Factory: FORBIDDEN");
        factory.setFeeToSetter(unauthorized);
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
