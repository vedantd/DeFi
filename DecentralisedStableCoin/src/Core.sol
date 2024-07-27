// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDai} from "./interfaces/IDai.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {MathLib} from "./libraries/MathLib.sol";
import "forge-std/console.sol";

contract Core is ReentrancyGuard {
    using MathLib for uint256;

    // Errors
    error Core__TransferFailed(string reason);
    error Core__InsufficientCollateral();
    error Core__RepayAmountExceedsDebt();
    error Core__HealthFactorOk();
    error Core__HealthFactorNotImproved();
    error Core__NeedsMoreThanZero();
    error Core__TokenNotAllowed(address token);
    error Core__BreaksHealthFactor(uint256 healthFactorValue);
    error Core__MintFailed();

    // Modifiers
    modifier amountMoreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Core__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (priceFeeds[token] == address(0)) {
            revert Core__TokenNotAllowed(token);
        }
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
    event CollateralRedeemed(
        address indexed redeemFrom,
        address indexed redeemTo,
        address token,
        uint256 amount
    );

    // State Variables
    mapping(address => address) public priceFeeds;
    mapping(address => mapping(address => uint256)) public collateralBalances;
    mapping(address => uint256) public daiDebt;
    address[] public allowedTokens;

    IDai private i_daiContract;
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
            allowedTokens.push(tokenAddresses[i]);
        }
        i_daiContract = IDai(daiContractAddress);
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
        console.log(
            "depositCollateral: token = %s, amount = %s",
            tokenCollateralAddress,
            amountCollateral
        );
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
            revert Core__TransferFailed("Deposit collateral transfer failed");
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
        console.log(
            "withdrawCollateral: token = %s, amount = %s",
            tokenCollateralAddress,
            amountCollateral
        );
        uint256 userCollateral = collateralBalances[msg.sender][
            tokenCollateralAddress
        ];
        console.log("withdrawCollateral: userCollateral = %s", userCollateral);
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
            revert Core__TransferFailed("Withdraw collateral transfer failed");
        }
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function mintDai(
        uint256 amountDai
    ) public amountMoreThanZero(amountDai) nonReentrant {
        console.log("mintDai: amount = %s", amountDai);
        daiDebt[msg.sender] += amountDai;
        revertIfHealthFactorIsBroken(msg.sender);
        bool success = i_daiContract.mint(msg.sender, amountDai);
        if (!success) {
            revert Core__MintFailed();
        }
    }

    function depositCollateralAndMintDai(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDaiToMint
    ) external {
        console.log(
            "depositCollateralAndMintDai: token = %s, amountCollateral = %s, amountDaiToMint = %s",
            tokenCollateralAddress,
            amountCollateral,
            amountDaiToMint
        );
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDai(amountDaiToMint);
    }

    function redeemCollateralForDai(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDaiToBurn
    )
        external
        amountMoreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
    {
        console.log(
            "redeemCollateralForDai: token = %s, amountCollateral = %s, amountDaiToBurn = %s",
            tokenCollateralAddress,
            amountCollateral,
            amountDaiToBurn
        );
        _burnDai(amountDaiToBurn, msg.sender, msg.sender);
        _redeemCollateral(
            tokenCollateralAddress,
            amountCollateral,
            msg.sender,
            msg.sender
        );
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        amountMoreThanZero(amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        console.log(
            "redeemCollateral: token = %s, amount = %s",
            tokenCollateralAddress,
            amountCollateral
        );
        _redeemCollateral(
            tokenCollateralAddress,
            amountCollateral,
            msg.sender,
            msg.sender
        );
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function burnDai(uint256 amount) external amountMoreThanZero(amount) {
        console.log("burnDai: amount = %s", amount);
        _burnDai(amount, msg.sender, msg.sender);
        revertIfHealthFactorIsBroken(msg.sender); // I don't think this would ever hit...
    }

    function liquidate(
        address collateral,
        address user,
        uint256 debtToCover
    ) external amountMoreThanZero(debtToCover) nonReentrant {
        console.log(
            "liquidate: collateral = %s, user = %s, debtToCover = %s",
            collateral,
            user,
            debtToCover
        );
        uint256 startingUserHealthFactor = getHealthFactor(user);
        console.log(
            "liquidate: startingUserHealthFactor = %s",
            startingUserHealthFactor
        );
        if (startingUserHealthFactor >= PRECISION) {
            revert Core__HealthFactorOk();
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
            revert Core__TransferFailed("Liquidate transfer failed");
        }
        daiDebt[user] -= debtToCover;
        i_daiContract.burn(debtToCover);
        uint256 endingUserHealthFactor = getHealthFactor(user);
        console.log(
            "liquidate: endingUserHealthFactor = %s",
            endingUserHealthFactor
        );
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert Core__HealthFactorNotImproved();
        }
        revertIfHealthFactorIsBroken(msg.sender);
    }

    // Public View Functions
    function getHealthFactor(address user) public view returns (uint256) {
        (
            uint256 totalDaiDebt,
            uint256 collateralValueInUsd
        ) = getAccountInformation(user);
        return
            MathLib.calculateHealthFactor(
                totalDaiDebt,
                collateralValueInUsd,
                LIQUIDATION_THRESHOLD
            );
    }

    function getUsdValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        IPriceFeed priceFeed = IPriceFeed(priceFeeds[token]);
        uint256 price = priceFeed.getLatestPrice(token);
        return (amount * price) / MathLib.PRECISION;
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
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            address token = allowedTokens[i];
            uint256 amount = collateralBalances[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    // Internal Functions
    function revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = getHealthFactor(user);
        console.log(
            "revertIfHealthFactorIsBroken: userHealthFactor = %s",
            userHealthFactor
        );
        if (userHealthFactor < PRECISION) {
            revert Core__InsufficientCollateral();
        }
    }

    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address from,
        address to
    ) private {
        collateralBalances[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(
            from,
            to,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transfer(
            to,
            amountCollateral
        );
        if (!success) {
            revert Core__TransferFailed("Redeem collateral transfer failed");
        }
    }

    function _burnDai(
        uint256 amountDaiToBurn,
        address onBehalfOf,
        address daiFrom
    ) private {
        console.log(
            "_burnDai: amount = %s, onBehalfOf = %s, daiFrom = %s",
            amountDaiToBurn,
            onBehalfOf,
            daiFrom
        );
        daiDebt[onBehalfOf] -= amountDaiToBurn;
        bool success = i_daiContract.transferFrom(
            daiFrom,
            address(this),
            amountDaiToBurn
        );
        if (!success) {
            revert Core__TransferFailed("Burn DAI transfer failed");
        }
        i_daiContract.burn(amountDaiToBurn);
    }
}
