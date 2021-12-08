// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFishingTownPriceOracle {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
}
