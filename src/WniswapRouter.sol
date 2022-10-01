// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./interfaces/IWniswapPair.sol";
import "./interfaces/IWniswapFactory.sol";
import "./WniswapLibrary.sol";

contract WniswapRouter {

    error SafeTransferFailed();
    error InsufficientBAmount();
    error InsufficientAAmount();
    error InsufficientOutputAmount();

    IWniswapFactory factory;

    constructor(address factoryAddress) {
        factory = IWniswapFactory(factoryAddress);
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

        address pairAddress = WniswapLibrary.pairFor(
            address(factory),
            tokenA,
            tokenB
        );

        _safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
        _safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);
        liquidity = IWniswapPair(pairAddress).mint(to);
    }
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAmin,
        uint256 amountBMin,
        address to
    ) public returns (uint256 amountA, uint256 amountB) {
        address pair = WniswapLibrary.pairFor(
            address(factory),
            tokenA,
            tokenB
        );

        IWniswapPair(pair).transferFrom(msg.sender, pair, liquidity);
        (amountA, amountB) = IWniswapPair(pair).burn(to);

        if (amountA < amountAmin) revert InsufficientAAmount();
        if (amountA < amountBMin) revert InsufficientBAmount();
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public returns (uint256[] memory amounts) {
        amounts = WniswapLibrary.getAmountsIn(
            address(factory),
            amountIn,
            path
        );

        if(amounts[amounts.length - 1] < amountOutMin)
            revert InsufficientOutputAmount();

        _safeTransferFrom(
            path[0],
            msg.sender,
            WniswapLibrary.pairFor(address(factory), path[0], path[1]),
            amounts[0]
        );

        _swap(amounts, path, to);
    }

    function _swap(
        uint256[] memory amounts,
        addresst[] memory path,
        address to_
    ) internal {
        for( uint256 i ; i < path.length -1; i++){
            (address input, address output) = (path[i] , path[i+1]);
            (address token0, ) = WniswapLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));

            address to = i < path.length -2
                ? WniswapLibrary.pairFor(
                    address(factory),
                    output,
                    path[i + 2]
                )
                : to_;
            
            IWniswapPair(
                WniswapLibrary.pairFor(address(factory), input, output)
            ).swap(amount0Out, amount1Out, to, "");
        }
    }

    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB){
        (uint256 reserveA, uint256 reserveB) = WniswapLibrary.getReserves(
            address(factory),
            tokenA,
            tokenB
        );

        if (reserveA == 0 && reserveB == 0){
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = WniswapLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );

            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            }else{
                uint256 amountAOptimal = WniswapLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );

                assert(amountAOptimal <= amountADesired);

                if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address, address, uint256)",
                from,
                to,
                value
            )
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert SafeTransferFailed();
    }

}