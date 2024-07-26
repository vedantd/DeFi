# X * Y = K Dex 

## Spec
## LP Token Calculation

When providing liquidity, the amount of LP tokens minted is determined as follows:

1. **Initial Liquidity Provision**: If no liquidity exists in the pool (`totalSupply` is 0):
   - The liquidity provided is calculated as:
     \[
     \text{liquidity} = \sqrt{\text{amount0} \times \text{amount1}} - \text{MINIMUM\_LIQUIDITY}
     \]
   - The `MINIMUM_LIQUIDITY` (1000 LP tokens) is permanently locked.

2. **Subsequent Liquidity Provision**: If liquidity already exists:
   - The liquidity provided is calculated based on the smaller ratio of the added amounts to the current reserves:
     \[
     \text{liquidity} = \min\left(\frac{\text{amount0} \times \text{totalSupply}}{\text{reserve0}}, \frac{\text{amount1} \times \text{totalSupply}}{\text{reserve1}}\right)
     \]

## Project Progress

![Progress](https://progress-bar.dev/25/?width=500)

## Test-Driven Development (TDD) Approach

This project follows Test-Driven Development principles, ensuring high code quality, comprehensive test coverage, and protection against regression.

## Project Progress Log

### Core Contract Implementation

| Feature | Status |
|---------|--------|
| Initial Setup | Completed |
| Basic Pair Functionality | Completed |
| x * y = k Curve Implementation | In Progress |
| Swap Function (using x * y = k) | In Progress |
| Liquidity Provision (Minting) | Completed |
| Liquidity Removal (Burning) | Pending |
| Price Impact Calculation | Pending |
| Protocol Fee Implementation | Pending |
| Reentrancy Protection | Pending |
| Price Oracle Functionality | Pending |
| Flash Swap Functionality | Pending |
| Syncing and Skimming | Pending |

### Additional Contracts

| Contract | Status |
|----------|--------|
| Factory Contract | Pending |
| Router Contract | Pending |

## Detailed Progress

### 1. Initial contracts (Completed)
- Set up the project using Foundry
- Created basic contract structure for `Pair.sol`
- Implemented constructor and initialize function

### 2. Basic Pair Functionality (Completed)
- Implemented `token0` and `token1` storage
- Added `getReserves` function
- Implemented `MINIMUM_LIQUIDITY` constant

### 3. x * y = k Curve Implementation (In Progress)
- Implementing core swap logic based on constant product formula
- Ensuring reserves always maintain x * y = k after swaps (minus fees)

### 4. Swap Function (In Progress)
- Implementing `swap` function using x * y = k curve
- Calculating input and output amounts based on constant product formula
- Handling edge cases and ensuring no overflow/underflow

### 5. Testing
- Created `PairTest.t.sol` for comprehensive testing
- Implemented tests for initialization and basic functions
- Developing tests for x * y = k curve behavior and swap function

## Future Implementations

6. Liquidity Removal (Burning)
7. Price Impact Calculation
8. Protocol Fee Implementation
9. Reentrancy Protection
10. Price Oracle Functionality
11. Flash Swap Functionality
12. Syncing and Skimming
13. Factory Contract
14. Router Contract
15. Gas Optimization
16. Documentation and Deployment

This project aims to create a functional clone of Uniswap V2, focusing on the core x * y = k mechanism and building additional features on top of this foundation.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.




