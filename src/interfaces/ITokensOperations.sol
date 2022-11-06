// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokensOperations {
    // --- STRUCTS ---

    // --- ERRORS ---
    error TokenSwapFailed(address token);
    error RefundClaimFailed();
    error InsufficientFunds(uint256 required, uint256 current);

    // --- EVENTS ---
    event TokenBought(
        address indexed user,
        uint256 strategyId,
        address token,
        uint256 wethAmountSpent,
        uint256 tokenAmountBought
    );

    event ExchangeProxyChanged(address exchangeProxy);

    // --- FUNCTIONS ---
    function depositETH(address user_, uint256 strategyId_) external payable;

    function claimRefunds() external;

    function buyToken(
        address user_,
        uint256 strategyId_,
        IERC20 token_,
        uint256 wETHAmount_,
        address spender_,
        bytes calldata swapCallData_
    ) external payable;

    function setExchangeProxy(address exchangeProxy_) external;
}
