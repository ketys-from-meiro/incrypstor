// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// just a partial WETH contract interface
interface IWETH is IERC20 {
    function deposit() external payable;
}
