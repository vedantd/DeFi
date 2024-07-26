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
        pair.initialize(token0, token1);
    }

    function testSwap() public {
        // Add initial liquidity
        MockERC20(token0).mint(address(pair), 10 ether);
        MockERC20(token1).mint(address(pair), 10 ether);
        pair.updateReserves(10 ether, 10 ether);

        // Prepare for swap
        MockERC20(token0).mint(address(this), 1 ether);
        IERC20(token0).transfer(address(pair), 1 ether);

        // Perform swap
        uint amountOut = 0.9 ether; // Expecting to receive slightly less than 1 due to the fee
        pair.swap(0, amountOut, address(this));

        // Check balances after swap
        assertEq(
            IERC20(token1).balanceOf(address(this)),
            amountOut,
            "Should have received the swapped amount of token1"
        );

        // Check updated reserves
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        assertEq(
            reserve0,
            11 ether,
            "Reserve0 should be increased by the swapped amount"
        );
        assertEq(
            reserve1,
            10 ether - amountOut,
            "Reserve1 should be decreased by the swapped amount"
        );
    }
}

// MockERC20 contract remains the same

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
