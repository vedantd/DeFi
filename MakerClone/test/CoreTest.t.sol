// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Core.sol";
import "../src/Dai.sol";
import "../src/MockPriceFeed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 ether);
    }
}

contract CoreTest is Test {
    Core core;
    Dai dai;
    MockPriceFeed priceFeed;
    MockERC20 mockToken;

    address tokenAddress;
    address[] tokenAddresses;
    address[] priceFeedAddresses;

    event Log(string message, uint256 value);

    function setUp() public {
        dai = new Dai(address(this));
        mockToken = new MockERC20();
        tokenAddress = address(mockToken);
        tokenAddresses = [tokenAddress];

        priceFeed = new MockPriceFeed(2000 * 1e8); // 2000 USD initial price
        priceFeedAddresses = [address(priceFeed)];

        core = new Core(tokenAddresses, priceFeedAddresses, address(dai));

        dai.mint(address(this), 1000000 ether);
        dai.approve(address(core), type(uint256).max);
        mockToken.approve(address(core), type(uint256).max);
    }

    function testDepositCollateral() public {
        emit Log("Starting testDepositCollateral", 0);
        uint256 depositAmount = 500 ether;

        uint256 initialBalance = mockToken.balanceOf(address(this));
        emit Log("Initial token balance", initialBalance);

        try core.depositCollateral(tokenAddress, depositAmount) {
            uint256 collateralBalance = core.collateralBalances(
                address(this),
                tokenAddress
            );
            emit Log("Collateral balance after deposit", collateralBalance);
            assertEq(
                collateralBalance,
                depositAmount,
                "Collateral balance should match deposit amount"
            );
            assertEq(
                mockToken.balanceOf(address(core)),
                depositAmount,
                "Core contract should have received tokens"
            );
        } catch Error(string memory reason) {
            emit Log("Deposit failed", 0);
            emit Log(reason, 0);
            fail();
        }
    }

    function testWithdrawCollateral() public {
        emit Log("Starting testWithdrawCollateral", 0);
        uint256 depositAmount = 500 ether;
        uint256 withdrawAmount = 200 ether;

        core.depositCollateral(tokenAddress, depositAmount);
        uint256 initialCollateralBalance = core.collateralBalances(
            address(this),
            tokenAddress
        );
        emit Log("Initial collateral balance", initialCollateralBalance);

        try core.withdrawCollateral(tokenAddress, withdrawAmount) {
            uint256 finalCollateralBalance = core.collateralBalances(
                address(this),
                tokenAddress
            );
            emit Log("Final collateral balance", finalCollateralBalance);
            assertEq(
                finalCollateralBalance,
                depositAmount - withdrawAmount,
                "Collateral balance should be reduced by withdrawal amount"
            );
        } catch Error(string memory reason) {
            emit Log("Withdrawal failed", 0);
            emit Log(reason, 0);
            fail();
        }
    }

    // function testMintDai() public {
    //     emit Log("Starting testMintDai", 0);
    //     uint256 depositAmount = 1000 ether;
    //     uint256 mintAmount = 100 ether;

    //     core.depositCollateral(tokenAddress, depositAmount);
    //     uint256 initialDaiBalance = dai.balanceOf(address(this));
    //     emit Log("Initial DAI balance", initialDaiBalance);

    //     uint256 price = priceFeed.getLatestPrice(tokenAddress);
    //     console.log("Token price: ", price);

    //     uint256 collateralValueInUsd = core.getUsdValue(
    //         tokenAddress,
    //         depositAmount
    //     );
    //     console.log("Collateral value in USD: ", collateralValueInUsd);

    //     uint256 healthFactor = core.getHealthFactor(address(this));
    //     console.log("Initial health factor: ", healthFactor);

    //     try core.mintDai(mintAmount) {
    //         // ... (rest of the function remains the same)
    //     } catch Error(string memory reason) {
    //         emit Log("Minting failed", 0);
    //         emit Log(reason, 0);

    //         // Add these lines to get more information about the state after failure
    //         healthFactor = core.getHealthFactor(address(this));
    //         console.log("Health factor after failed mint: ", healthFactor);

    //         uint256 collateralBalance = core.collateralBalances(
    //             address(this),
    //             tokenAddress
    //         );
    //         console.log("Collateral balance: ", collateralBalance);

    //         fail();
    //     }
    // }

    // function testBurnDai() public {
    //     emit Log("Starting testBurnDai", 0);
    //     uint256 depositAmount = 1000 ether;
    //     uint256 mintAmount = 100 ether;
    //     uint256 burnAmount = 50 ether;

    //     core.depositCollateral(tokenAddress, depositAmount);
    //     core.mintDai(mintAmount);

    //     uint256 initialDaiBalance = dai.balanceOf(address(this));
    //     uint256 initialDebt = core.daiDebt(address(this));
    //     emit Log("Initial DAI balance", initialDaiBalance);
    //     emit Log("Initial debt", initialDebt);

    //     try core.burnDai(burnAmount) {
    //         uint256 finalDaiBalance = dai.balanceOf(address(this));
    //         uint256 finalDebt = core.daiDebt(address(this));
    //         emit Log("Final DAI balance", finalDaiBalance);
    //         emit Log("Final debt", finalDebt);
    //         assertEq(
    //             finalDaiBalance,
    //             initialDaiBalance - burnAmount,
    //             "DAI balance should decrease by burn amount"
    //         );
    //         assertEq(
    //             finalDebt,
    //             initialDebt - burnAmount,
    //             "Debt should decrease by burn amount"
    //         );
    //     } catch Error(string memory reason) {
    //         emit Log("Burning failed", 0);
    //         emit Log(reason, 0);
    //         fail();
    //     }
    // }

    function testFailWithdrawMoreThanCollateral() public {
        emit Log("Starting testFailWithdrawMoreThanCollateral", 0);
        uint256 depositAmount = 500 ether;
        uint256 withdrawAmount = 600 ether;

        core.depositCollateral(tokenAddress, depositAmount);
        core.withdrawCollateral(tokenAddress, withdrawAmount);
    }

    function testFailBurnMoreThanDebt() public {
        emit Log("Starting testFailBurnMoreThanDebt", 0);
        uint256 depositAmount = 500 ether;
        uint256 mintAmount = 200 ether;
        uint256 burnAmount = 300 ether;

        core.depositCollateral(tokenAddress, depositAmount);
        core.mintDai(mintAmount);
        core.burnDai(burnAmount);
    }
}
