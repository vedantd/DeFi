import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import './App.css';

// Import your ABI files
import FactoryABI from './abis/Factory.json';
import RouterABI from './abis/Router.json';
import IERC20ABI from './abis/IERC20.json';
import PairABI from './abis/Pair.json';

const FACTORY_ADDRESS = '0xC4A0fCBE18A2c0ed64B956f03463ED0Db0CB30a1';
const ROUTER_ADDRESS = '0xA2854DE979D00562F19b84bA4d13E38011b1c2f3';
const TOKEN_A_ADDRESS = '0xef46cC8F97B06F1c3fdD995340f9BEf01B16553A';
const TOKEN_B_ADDRESS = '0x6f7D45d80559799923AB703785b96EbDC0e6Ea8d';

function App() {
  const [account, setAccount] = useState(null);
  const [factory, setFactory] = useState(null);
  const [router, setRouter] = useState(null);
  const [amountIn, setAmountIn] = useState('');
  const [liquidityInfo, setLiquidityInfo] = useState({});
  const [expectedOutput, setExpectedOutput] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isInitialized, setIsInitialized] = useState(false);

  useEffect(() => {
    const init = async () => {
      if (typeof window.ethereum !== 'undefined') {
        try {
          const [account] = await window.ethereum.request({ method: 'eth_requestAccounts' });
          setAccount(account);

          const provider = new ethers.providers.Web3Provider(window.ethereum);
          const signer = provider.getSigner();

          const factory = new ethers.Contract(FACTORY_ADDRESS, FactoryABI, signer);
          const router = new ethers.Contract(ROUTER_ADDRESS, RouterABI, signer);

          setFactory(factory);
          setRouter(router);
          setIsInitialized(true);
        } catch (error) {
          console.error("Initialization error:", error);
          setError("Failed to initialize. Please make sure you're connected to the correct network.");
        }
      }
    };

    init();
  }, []);

  useEffect(() => {
    const updateExpectedOutput = async () => {
      if (isInitialized && amountIn) {
        try {
          const tokenIn = new ethers.Contract(TOKEN_A_ADDRESS, IERC20ABI, router.signer);
          const decimals = await tokenIn.decimals();
          const parsedAmountIn = ethers.utils.parseUnits(amountIn, decimals);
          const output = await getAmountOut(parsedAmountIn, TOKEN_A_ADDRESS, TOKEN_B_ADDRESS);
          if (output) {
            const tokenOut = new ethers.Contract(TOKEN_B_ADDRESS, IERC20ABI, router.signer);
            const decimalsOut = await tokenOut.decimals();
            setExpectedOutput(ethers.utils.formatUnits(output, decimalsOut));
          }
        } catch (error) {
          console.error("Error updating expected output:", error);
          setError("Failed to calculate expected output. Please try again.");
        }
      }
    };

    updateExpectedOutput();
  }, [amountIn, router, isInitialized]);

  const createPair = async () => {
    if (!isInitialized) {
      setError("Contracts are not initialized. Please wait or refresh the page.");
      return;
    }
    try {
      setError('');
      setSuccess('');
      const tx = await factory.createPair(TOKEN_A_ADDRESS, TOKEN_B_ADDRESS);
      await tx.wait();
      setSuccess('Pair created successfully');
    } catch (error) {
      console.error('Error creating pair:', error);
      setError('Failed to create pair. Please check your input and try again.');
    }
  };

  const addLiquidity = async () => {
    if (!isInitialized) {
      setError("Contracts are not initialized. Please wait or refresh the page.");
      return;
    }
    try {
      setError('');
      setSuccess('');
      const tokenA = new ethers.Contract(TOKEN_A_ADDRESS, IERC20ABI, router.signer);
      const tokenB = new ethers.Contract(TOKEN_B_ADDRESS, IERC20ABI, router.signer);

      const amountA = ethers.utils.parseUnits('1', await tokenA.decimals());
      const amountB = ethers.utils.parseUnits('1', await tokenB.decimals());

      console.log(`Approving ${ethers.utils.formatUnits(amountA, await tokenA.decimals())} TokenA`);
      let tx = await tokenA.approve(ROUTER_ADDRESS, amountA);
      await tx.wait();

      console.log(`Approving ${ethers.utils.formatUnits(amountB, await tokenB.decimals())} TokenB`);
      tx = await tokenB.approve(ROUTER_ADDRESS, amountB);
      await tx.wait();

      console.log('Adding liquidity...');
      tx = await router.addLiquidity(
        TOKEN_A_ADDRESS,
        TOKEN_B_ADDRESS,
        amountA,
        amountB,
        0,
        0,
        account,
        Math.floor(Date.now() / 1000) + 60 * 10, // 10 minutes from now
        { gasLimit: 300000 }
      );
      const receipt = await tx.wait();
      console.log('Liquidity added successfully', receipt);
      setSuccess('Liquidity added successfully');
    } catch (error) {
      console.error('Error adding liquidity:', error);
      setError('Failed to add liquidity. Please check your input and try again.');
    }
  };

  const getAmountOut = async (amountIn, tokenInAddress, tokenOutAddress) => {
    try {
      const tokenIn = new ethers.Contract(tokenInAddress, IERC20ABI, router.signer);
      const tokenOut = new ethers.Contract(tokenOutAddress, IERC20ABI, router.signer);
      const decimalsIn = await tokenIn.decimals();
      const decimalsOut = await tokenOut.decimals();
      const path = [tokenInAddress, tokenOutAddress];
      const amounts = await router.getAmountsOut(amountIn, path);
      console.log(`Expected output: ${ethers.utils.formatUnits(amounts[1], decimalsOut)}`);
      return amounts[1];
    } catch (error) {
      console.error('Error getting amount out:', error);
      return null;
    }
  };

  const checkBalanceAndAllowance = async (tokenAddress, amount) => {
    const token = new ethers.Contract(tokenAddress, IERC20ABI, router.signer);
    const decimals = await token.decimals();
    const balance = await token.balanceOf(account);
    const allowance = await token.allowance(account, ROUTER_ADDRESS);

    console.log(`Token Address: ${tokenAddress}`);
    console.log(`Decimals: ${decimals}`);
    console.log(`Balance: ${ethers.utils.formatUnits(balance, decimals)}`);
    console.log(`Allowance: ${ethers.utils.formatUnits(allowance, decimals)}`);
    console.log(`Required Amount: ${ethers.utils.formatUnits(amount, decimals)}`);

    if (balance.lt(amount)) {
      setError(`Insufficient balance. You have ${ethers.utils.formatUnits(balance, decimals)} tokens, but ${ethers.utils.formatUnits(amount, decimals)} are required.`);
      return false;
    }

    if (allowance.lt(amount)) {
      try {
        const tx = await token.approve(ROUTER_ADDRESS, ethers.constants.MaxUint256);
        await tx.wait();
        console.log('Approved max amount for Router');
      } catch (error) {
        console.error('Error approving tokens:', error);
        setError('Failed to approve tokens. Please try again.');
        return false;
      }
    }

    return true;
  };

  const swap = async () => {
    if (!isInitialized) {
      setError("Contracts are not initialized. Please wait or refresh the page.");
      return;
    }
    try {
      setError('');
      setSuccess('');

      const tokenIn = new ethers.Contract(TOKEN_A_ADDRESS, IERC20ABI, router.signer);
      const decimals = await tokenIn.decimals();
      const parsedAmountIn = ethers.utils.parseUnits(amountIn, decimals);

      if (!(await checkBalanceAndAllowance(TOKEN_A_ADDRESS, parsedAmountIn))) {
        return;
      }

      const amountOut = await getAmountOut(parsedAmountIn, TOKEN_A_ADDRESS, TOKEN_B_ADDRESS);
      if (!amountOut) {
        setError('Failed to get expected output amount');
        return;
      }

      const minAmountOut = amountOut.mul(95).div(100); // 5% slippage tolerance

      console.log('Swapping...');
      console.log(`Amount In: ${ethers.utils.formatUnits(parsedAmountIn, decimals)}`);
      console.log(`Min Amount Out: ${ethers.utils.formatUnits(minAmountOut, 18)}`); // Assuming TokenB has 18 decimals

      const tx = await router.swapExactTokensForTokens(
        parsedAmountIn,
        minAmountOut,
        [TOKEN_A_ADDRESS, TOKEN_B_ADDRESS],
        account,
        Math.floor(Date.now() / 1000) + 60 * 10, // 10 minutes from now
        { gasLimit: 300000 } // Increase gas limit if needed
      );
      await tx.wait();
      setSuccess('Swap executed successfully');
    } catch (error) {
      console.error('Error executing swap:', error);
      setError(`Failed to execute swap: ${error.message}`);
    }
  };

  const fetchLiquidityInfo = async () => {
    if (!isInitialized) {
      setError("Contracts are not initialized. Please wait or refresh the page.");
      return;
    }
    try {
      setError('');
      const pairAddress = await factory.getPair(TOKEN_A_ADDRESS, TOKEN_B_ADDRESS);
      if (pairAddress === ethers.constants.AddressZero) {
        console.log('Pair does not exist');
        setLiquidityInfo({});
        setError('Pair does not exist');
        return;
      }

      const pairContract = new ethers.Contract(pairAddress, PairABI, router.signer);
      const [reserve0, reserve1] = await pairContract.getReserves();
      const token0Address = await pairContract.token0();
      const token1Address = await pairContract.token1();

      const token0 = new ethers.Contract(token0Address, IERC20ABI, router.signer);
      const token1 = new ethers.Contract(token1Address, IERC20ABI, router.signer);
      const decimals0 = await token0.decimals();
      const decimals1 = await token1.decimals();

      setLiquidityInfo({
        pairAddress,
        reserve0: ethers.utils.formatUnits(reserve0, decimals0),
        reserve1: ethers.utils.formatUnits(reserve1, decimals1),
        token0Address,
        token1Address
      });
    } catch (error) {
      console.error('Error fetching liquidity info:', error);
      setError('Failed to fetch liquidity info. Please try again.');
    }
  };

  const approveTokenA = async () => {
    if (!isInitialized) {
      setError("Contracts are not initialized. Please wait or refresh the page.");
      return;
    }
    try {
      const tokenA = new ethers.Contract(TOKEN_A_ADDRESS, IERC20ABI, router.signer);
      const tx = await tokenA.approve(ROUTER_ADDRESS, ethers.constants.MaxUint256);
      await tx.wait();
      console.log('Approved max TokenA for router');
      setSuccess('Approved max TokenA for router');
    } catch (error) {
      console.error('Error approving TokenA:', error);
      setError('Failed to approve TokenA');
    }
  };

  const approveTokenB = async () => {
    if (!isInitialized) {
      setError("Contracts are not initialized. Please wait or refresh the page.");
      return;
    }
    try {
      const tokenB = new ethers.Contract(TOKEN_B_ADDRESS, IERC20ABI, router.signer);
      const tx = await tokenB.approve(ROUTER_ADDRESS, ethers.constants.MaxUint256);
      await tx.wait();
      console.log('Approved max TokenB for router');
      setSuccess('Approved max TokenB for router');
    } catch (error) {
      console.error('Error approving TokenB:', error);
      setError('Failed to approve TokenB');
    }
  };

  return (
    <div className="App">
      <h1>Uniswap v2 Clone</h1>
      <p>Connected Account: {account}</p>
      {error && <p style={{color: 'red'}}>{error}</p>}
      {success && <p style={{color: 'green'}}>{success}</p>}
      {!isInitialized && <p>Initializing contracts... Please wait.</p>}
      <div>
        <h2>Create Pair</h2>
        <button onClick={createPair} disabled={!isInitialized}>Create Pair</button>
      </div>
      <div>
        <h2>Add Liquidity</h2>
        <button onClick={addLiquidity} disabled={!isInitialized}>Add Liquidity (1 TokenA and 1 TokenB)</button>
      </div>
      <div>
        <h2>Approve Tokens</h2>
        <button onClick={approveTokenA} disabled={!isInitialized}>Approve TokenA</button>
        <button onClick={approveTokenB} disabled={!isInitialized}>Approve TokenB</button>
      </div>
      <div>
        <h2>Swap</h2>
        <input 
          type="text" 
          placeholder="Amount of TokenA to swap" 
          value={amountIn} 
          onChange={(e) => setAmountIn(e.target.value)} 
        />
        {expectedOutput && <p>Expected TokenB Output: {expectedOutput}</p>}
        <button onClick={swap} disabled={!isInitialized}>Swap TokenA for TokenB</button>
      </div>
      <div>
        <h2>Liquidity Info</h2>
        <button onClick={fetchLiquidityInfo} disabled={!isInitialized}>Fetch Liquidity Info</button>
        {liquidityInfo.pairAddress && (
          <div>
            <p>Pair Address: {liquidityInfo.pairAddress}</p>
            <p>Token 0 Address: {liquidityInfo.token0Address}</p>
            <p>Token 1 Address: {liquidityInfo.token1Address}</p>
            <p>Reserve 0: {liquidityInfo.reserve0}</p>
            <p>Reserve 1: {liquidityInfo.reserve1}</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;