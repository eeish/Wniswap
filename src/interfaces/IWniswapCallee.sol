// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IWniswapCallee{
    function wniswapCall(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external;
}