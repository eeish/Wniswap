// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./interfaces/IWniswapPair.sol";
import "./interfaces/IWniswapFactory.sol";

contract WniswapRouter {
    constructor(address factoryAddress) {
        factory = IWniswapFactory(factoryAddress)
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) 
        public
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        if (factory.pairs(tokenA, tokenB) == address(0)){
            factory.createPair(tokenA,tokenB);
        }

        (amountA,amountB) = _calculateLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        address pairAddress = Wniswap

    }

}