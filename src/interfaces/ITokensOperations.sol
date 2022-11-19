// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokensOperations {
    // --- STRUCTS ---

    // --- ERRORS ---
    error TokenSwapFailed(address token);
    error RefundClaimFailed();
    error InsufficientFunds(uint256 required, uint256 current);
    error WithdrawalFailed();

    // --- EVENTS ---
    event TokenBought(
        address indexed user,
        uint256 strategyId,
        address token,
        uint256 wethAmountSpent,
        uint256 tokenAmountBought,
        uint256 timestamp
    );
    event TokenSold(
        address indexed user,
        uint256 strategyId,
        address token,
        uint256 tokenAmountSpent,
        uint256 wethAmountBought,
        uint256 timestamp
    );

    event ExchangeProxyChanged(address exchangeProxy);

    // --- FUNCTIONS ---
    function depositETH(address user_, uint256 strategyId_) external payable;

    function withdrawAllETH(address user_, uint256 strategyId_) external;

    function claimRefunds(address user_) external;

    function buyToken(
        address user_,
        uint256 strategyId_,
        IERC20 token_,
        uint256 wETHAmount_,
        address spender_,
        bytes calldata swapCallData_
    ) external payable;

    function sellToken(
        address user_,
        uint256 strategyId_,
        IERC20 token_,
        uint256 tokenAmount_,
        address spender_,
        bytes calldata swapCallData_
    ) external payable;

    function getTokenBalance(
        address user_,
        uint256 strategyId_,
        address tokenAddr_
    ) external view returns (uint256);

    function setExchangeProxy(address exchangeProxy_) external;
}
