# X * Y = K DEX

## Overview
This project is implementing a decentralized exchange (DEX) based on the constant product formula (x * y = k), inspired by Uniswap V2. The project follows a test-driven development (TDD) approach to ensure high code quality and comprehensive test coverage.

## Project Progress

![Progress](https://progress-bar.dev/70/?width=500)

## Implemented Features

1. **Factory Contract**
   - Create new token pairs
   - Manage fee settings
   - Store and retrieve pair addresses

2. **Pair Contract**
   - Basic pair functionality
   - Liquidity provision (minting LP tokens)
   - Reserve management
   - Constant product formula implementation (x * y = k)
   - Swap functionality

3. **LP Token (V2LPToken)**
   - ERC20 functionality
   - Minting and burning mechanisms

4. **Router Contract**
   - Add liquidity
   - Remove liquidity
   - Swap exact tokens for tokens
   - Manual gas limit estimation for transactions

5. **Frontend Interface**
   - Create pairs
   - Add liquidity
   - Swap tokens
   - Fetch and display liquidity information

## Current Focus

- Enhancing swap functionality
- Adding more complex liquidity operations
- Improving frontend user experience

## Test Suite

- Comprehensive tests for Factory contract
- Tests for basic Pair contract functionality
- Tests for liquidity provision and swaps
- Tests for Router contract functions

## Upcoming Tasks

1. Enhance error handling and input validation
2. Implement price impact calculation
3. Add flash swap functionality
4. Implement price oracle
5. Optimize gas usage
6. Enhance documentation

## LP Token Calculation

When providing liquidity, the amount of LP tokens minted is determined as follows:

1. **Initial Liquidity Provision**: If no liquidity exists in the pool (`totalSupply` is 0):
   - The liquidity provided is calculated as:
     ```
     liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY
     ```
   - The `MINIMUM_LIQUIDITY` (1000 LP tokens) is permanently locked.

2. **Subsequent Liquidity Provision**: If liquidity already exists:
   - The liquidity provided is calculated based on the smaller ratio of the added amounts to the current reserves:
     ```
     liquidity = min((amount0 * totalSupply) / reserve0, (amount1 * totalSupply) / reserve1)
     ```

## Test-Driven Development (TDD) Approach

This project follows Test-Driven Development principles, ensuring high code quality, comprehensive test coverage, and protection against regression.

## Getting Started

1. Clone the repository
2. Install dependencies (Foundry required)
3. Run tests: `forge test`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
