# Uniswap V2 Clone Project

## Project Progress

![Progress](https://progress-bar.dev/25/?width=400)

## Test-Driven Development (TDD) Approach

This project strictly follows Test-Driven Development principles. For each feature:

1. We write failing tests that define the expected behavior
2. We implement the minimal code to pass the tests
3. We refactor the code while ensuring all tests still pass

This approach ensures high code quality, comprehensive test coverage, and helps prevent regression as we add new features.

## Project Progress Log

### Core Contract Implementation

- [x] Initial Setup
- [x] Basic Pair Functionality
- [x] Liquidity Provision (Minting)
- [ ] Liquidity Removal (Burning)
- [ ] Swapping Functionality
- [ ] Price Oracle Functionality
- [ ] Protocol Fee Implementation
- [ ] Reentrancy Protection
- [ ] Flash Swap Functionality
- [ ] Syncing and Skimming

### Additional Contracts

- [ ] Factory Contract
- [ ] Router Contract

### Testing and Optimization

- [x] Basic Pair Tests
- [ ] Comprehensive Swap Tests
- [ ] Factory Contract Tests
- [ ] Router Contract Tests
- [ ] Gas Optimization

### Documentation and Deployment

- [ ] Code Comments
- [ ] Developer Documentation
- [ ] User Guide
- [ ] Deployment Scripts

### Optional Enhancements

- [ ] Frontend Integration
- [ ] Security Audit

## Detailed Progress

### 1. Initial Setup ✅
- [x] Set up the project using Foundry
- [x] Created basic contract structure for `Pair.sol`
- [x] Implemented constructor and initialize function

### 2. Basic Pair Functionality ✅
- [x] Implemented `token0` and `token1` storage
- [x] Added `getReserves` function
- [x] Implemented `mint` function for liquidity provision
- [x] Added `MINIMUM_LIQUIDITY` constant

### 3. Testing ✅
- [x] Created `PairTest.t.sol` for comprehensive testing
- [x] Implemented tests for:
  - [x] Initialization
  - [x] Preventing double initialization
  - [x] Factory-only initialization
  - [x] Initial reserves state
  - [x] Liquidity minting (both equal and unequal token amounts)
- [x] Resolved issues with arithmetic overflow and ERC20 invalid receiver

### 4. Current State
Basic pair contract functionality is in place with liquidity provision (minting) working and tested.

## Future Implementations

### 5. Liquidity Removal (Burning) 🔜
- [ ] Implement `burn` function
- [ ] Add corresponding tests

### 6. Swapping Functionality
- [ ] Implement `swap` function
- [ ] Add tests for various swap scenarios

### 7. Price Oracle Functionality
- [ ] Implement price accumulator logic
- [ ] Update `_update` function to handle price accumulation
- [ ] Add tests for price oracle updates

### 8. Protocol Fee Implementation
- [ ] Add `kLast` storage
- [ ] Implement `_mintFee` function
- [ ] Modify `mint` and `burn` functions to handle protocol fees
- [ ] Add tests for fee collection scenarios

### 9. Reentrancy Protection
- [ ] Implement `lock` modifier
- [ ] Apply to relevant functions
- [ ] Add tests to ensure protection

### 10. Flash Swap Functionality
- [ ] Implement flash swap logic in `swap` function
- [ ] Add `uniswapV2Call` handling
- [ ] Create tests for flash swap scenarios

### 11. Syncing and Skimming
- [ ] Implement `sync` function
- [ ] Implement `skim` function
- [ ] Add tests for edge cases and recovery scenarios

### 12. Factory Contract
- [ ] Implement `UniswapV2Factory` contract
- [ ] Add pair creation functionality
- [ ] Implement tests for factory contract

### 13. Router Contract
- [ ] Implement `UniswapV2Router` contract
- [ ] Add high-level functions for easy interaction with pairs
- [ ] Implement comprehensive tests for router functionality

### 14. Gas Optimization
- [ ] Review and optimize gas usage
- [ ] Implement gas-saving techniques
- [ ] Add benchmarking tests

### 15. Documentation
- [ ] Add comprehensive comments to all contracts
- [ ] Create developer documentation
- [ ] Write user guide for interacting with the protocol

### 16. Deployment Scripts
- [ ] Create scripts for easy deployment to various networks
- [ ] Implement configuration files for different environments

### 17. Frontend Integration (Optional)
- [ ] Develop a basic frontend for interacting with the protocol
- [ ] Implement web3 connectivity

### 18. Security Audit
- [ ] Conduct internal security review
- [ ] Consider external audit if resources allow

This project aims to create a functional clone of Uniswap V2, focusing on core functionalities while providing a platform for learning and experimentation with DeFi protocols.