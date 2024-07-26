// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
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

    function testGetReserves() public {
        pair.initialize(token0, token1);

        // Initially, reserves should be zero
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair
            .getReserves();
        assertEq(reserve0, 0);
        assertEq(reserve1, 0);
        assertEq(blockTimestampLast, 0);

        // TODO: We'll add more tests here after implementing liquidity provision
    }

    function testMintLiquidity() public {
        pair.initialize(token0, token1);

        // Mint some tokens to this contract
        MockERC20(token0).mint(address(this), 10 ether);
        MockERC20(token1).mint(address(this), 10 ether);

        // Approve the pair contract to spend tokens
        IERC20(token0).approve(address(pair), 10 ether);
        IERC20(token1).approve(address(pair), 10 ether);

        // Transfer tokens to the pair contract
        IERC20(token0).transfer(address(pair), 10 ether);
        IERC20(token1).transfer(address(pair), 10 ether);

        // Add liquidity
        uint256 liquidity = pair.mint(address(this));

        console.log("Liquidity minted:", liquidity);

        // Check liquidity minted
        assertGt(liquidity, 0, "Should have minted liquidity tokens");

        // Check reserves
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        assertEq(reserve0, 10 ether, "Reserve0 should be 10 ether");
        assertEq(reserve1, 10 ether, "Reserve1 should be 10 ether");

        // Check liquidity balance
        assertEq(
            pair.balanceOf(address(this)),
            liquidity,
            "Liquidity balance should match minted amount"
        );
    }

    function testMintLiquidityUnequal() public {
        pair.initialize(token0, token1);

        // Mint some tokens to this contract
        MockERC20(token0).mint(address(this), 10 ether);
        MockERC20(token1).mint(address(this), 5 ether);

        // Approve the pair contract to spend tokens
        IERC20(token0).approve(address(pair), 10 ether);
        IERC20(token1).approve(address(pair), 5 ether);

        // Transfer tokens to the pair contract
        IERC20(token0).transfer(address(pair), 10 ether);
        IERC20(token1).transfer(address(pair), 5 ether);

        // Add liquidity
        uint256 liquidity = pair.mint(address(this));

        console.log("Liquidity minted:", liquidity);

        // Check liquidity minted
        assertGt(liquidity, 0, "Should have minted liquidity tokens");

        // Check reserves
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        assertEq(reserve0, 10 ether, "Reserve0 should be 10 ether");
        assertEq(reserve1, 5 ether, "Reserve1 should be 5 ether");

        // Check liquidity balance
        assertEq(
            pair.balanceOf(address(this)),
            liquidity,
            "Liquidity balance should match minted amount"
        );
    }
}

// Mock ERC20 token for testing
contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(address account, uint256 amount) external {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}
