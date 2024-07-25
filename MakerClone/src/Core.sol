// SPDX-License-Identifier: MIT
// SPEC
// Deposit collateral mint dai (wETH,wBTC)
// Repay DAI
// Withdraw collateral
// Liquidate
// threshold 150% (collateral value / dai value)
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Dai} from "./Dai.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Core is ReentrancyGuard {
    // Errors
    error DSCEngine__TransferFailed();
    error DSCEngine__InsufficientCollateral();
    error DSCEngine__RepayAmountExceedsDebt();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    // Modifiers
    modifier amountMoreThanZero(uint256 amount) {
        require(amount > 0, "Amount must be more than zero");
        _;
    }

    modifier isAllowedToken(address token) {
        require(priceFeeds[token] != address(0), "Token not allowed");
        _;
    }

    // Events
    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );

    event CollateralWithdrawn(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );

    // State Variables
    mapping(address => address) public priceFeeds;
    mapping(address => mapping(address => uint256)) public collateralBalances;
    mapping(address => uint256) public daiDebt;

    Dai private i_daiContract;
    uint256 private constant LIQUIDATION_THRESHOLD = 150; // 150%
    uint256 private constant LIQUIDATION_BONUS = 10; // 10%
    uint256 private constant PRECISION = 1e18;

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address daiContractAddress
    ) {
        require(
            tokenAddresses.length == priceFeedAddresses.length,
            "Array length mismatch"
        );
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_daiContract = Dai(daiContractAddress);
    }

    // External Functions
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        public
        amountMoreThanZero(amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        collateralBalances[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;
        emit CollateralDeposited(
            msg.sender,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function withdrawCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        amountMoreThanZero(amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        uint256 userCollateral = collateralBalances[msg.sender][
            tokenCollateralAddress
        ];
        require(userCollateral >= amountCollateral, "Insufficient collateral");
        collateralBalances[msg.sender][
            tokenCollateralAddress
        ] -= amountCollateral;
        emit CollateralWithdrawn(
            msg.sender,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transfer(
            msg.sender,
            amountCollateral
        );
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function mintDai(
        uint256 amountDai
    ) external amountMoreThanZero(amountDai) nonReentrant {
        daiDebt[msg.sender] += amountDai;
        revertIfHealthFactorIsBroken(msg.sender);
        bool success = i_daiContract.mint(msg.sender, amountDai);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function repayDai(
        uint256 amountDai
    ) external amountMoreThanZero(amountDai) nonReentrant {
        uint256 userDebt = daiDebt[msg.sender];
        require(userDebt >= amountDai, "Repay amount exceeds debt");
        daiDebt[msg.sender] -= amountDai;
        bool success = i_daiContract.transferFrom(
            msg.sender,
            address(this),
            amountDai
        );
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        i_daiContract.burn(amountDai);
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function liquidate(
        address collateral,
        address user,
        uint256 debtToCover
    ) external amountMoreThanZero(debtToCover) nonReentrant {
        uint256 startingUserHealthFactor = getHealthFactor(user);
        if (startingUserHealthFactor >= PRECISION) {
            revert DSCEngine__HealthFactorOk();
        }
        uint256 collateralValueInUsd = getUsdValue(collateral, debtToCover);
        uint256 bonusCollateral = (collateralValueInUsd * LIQUIDATION_BONUS) /
            100;
        uint256 totalCollateralToLiquidate = collateralValueInUsd +
            bonusCollateral;
        collateralBalances[user][collateral] -= totalCollateralToLiquidate;
        bool success = IERC20(collateral).transfer(
            msg.sender,
            totalCollateralToLiquidate
        );
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        daiDebt[user] -= debtToCover;
        i_daiContract.burn(debtToCover);
        uint256 endingUserHealthFactor = getHealthFactor(user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        revertIfHealthFactorIsBroken(msg.sender);
    }

    // Public View Functions
    function getHealthFactor(address user) public view returns (uint256) {
        (
            uint256 totalDaiDebt,
            uint256 collateralValueInUsd
        ) = getAccountInformation(user);
        return calculateHealthFactor(totalDaiDebt, collateralValueInUsd);
    }

    function calculateHealthFactor(
        uint256 totalDaiDebt,
        uint256 collateralValueInUsd
    ) public pure returns (uint256) {
        if (totalDaiDebt == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd *
            LIQUIDATION_THRESHOLD) / 100;
        return (collateralAdjustedForThreshold * PRECISION) / totalDaiDebt;
    }

    function getUsdValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        // Implement this function based on your price feed logic
        // This is a placeholder implementation
        return amount * 2; // Assume each token is worth 2 USD
    }

    function getAccountInformation(
        address user
    ) public view returns (uint256 totalDaiDebt, uint256 collateralValueInUsd) {
        totalDaiDebt = daiDebt[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    function getAccountCollateralValue(
        address user
    ) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < priceFeeds.length; i++) {
            address token = priceFeeds[i];
            uint256 amount = collateralBalances[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    // Private Functions
    function revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = getHealthFactor(user);
        if (userHealthFactor < PRECISION) {
            revert DSCEngine__InsufficientCollateral();
        }
    }
}
