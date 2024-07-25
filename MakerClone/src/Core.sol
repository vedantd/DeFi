// SPDX-License-Identifier: MIT
// SPEC
// Deposit collateral mint dai (wETH,wBTC)
// Repay DAI
// Withdraw collateral
// Liquidate
// threshold 150% (collateral value / dai value)
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Dai} from "./Dai.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Core is ReentrancyGuard {
    //Errors//
    error DSCEngine__TransferFailed();

    //Modifiers//
    modifier amountMoreThanZero(uint256 amount) {
        require(amount > 0, "Amount must be more than zero");
        _;
    }
    modifier isAllowedToken(address token) {
        require(priceFeeds[token] != address(0), "Token not allowed");
        _;
    }
    //Events//
    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );
    //State Variables//
    mapping(address token => address priceFeed) public priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) collateralBalances;
    Dai private i_daiContract;

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddress,
        address daiContractAddress
    ) {
        require(
            tokenAddresses.length == priceFeedAddress.length,
            "Array length mismatch"
        );
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            priceFeeds[tokenAddresses[i]] = priceFeedAddress[i];
        }
        i_daiContract = Dai(daiContractAddress);
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     */
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

    function withdrawCollateral() external {}

    function mintDai() external {}

    function repayDai() external {}

    function liquidate() external {}

    function getHealthFactor() external {}
}
