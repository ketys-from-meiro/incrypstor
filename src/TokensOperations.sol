// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IWETH.sol";
import "./interfaces/IApprovedTokens.sol";
import "./interfaces/ITokensOperations.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokensOperations is ITokensOperations, Ownable {
    // 0x ExchangeProxy address
    address public exchangeProxy;
    IWETH public immutable wETH;
    IApprovedTokens public approvedTokens;
    mapping(address => mapping(uint256 => mapping(address => uint256))) private _userStrategyTokenBalance;
    mapping(address => mapping(uint256 => uint256)) private _userStrategySpendableWETH;
    mapping(address => uint256) public userRefundsAmount;

    constructor(
        address exchangeProxy_,
        IWETH wETH_,
        address approvedTokens_
    ) {
        exchangeProxy = exchangeProxy_;
        wETH = wETH_;
        approvedTokens = IApprovedTokens(approvedTokens_);
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    function depositETH(address user_, uint256 strategyId_) external payable {
        // TODO: can be called only by StrategiesManager contract
        _userStrategySpendableWETH[user_][strategyId_] += msg.value;
        wETH.deposit{value: msg.value}();
    }

    // Swaps wETH to token_ using 0x-API quote
    // payable because ETH equal to the `value` field from the API response must be provided
    function buyToken(
        address user_,
        uint256 strategyId_,
        IERC20 token_,
        uint256 wETHAmount_,
        address spender_,
        bytes calldata swapCallData_
    ) external payable {
        // TODO: can be called only by StrategiesManager contract
        if (_userStrategySpendableWETH[user_][strategyId_] < wETHAmount_) {
            revert InsufficientFunds({required: wETHAmount_, current: _userStrategySpendableWETH[user_][strategyId_]});
        }

        _userStrategySpendableWETH[user_][strategyId_] -= wETHAmount_;

        uint256 prevTokenAmount = token_.balanceOf(address(this));
        uint256 prevTotalRefundsAmount = address(this).balance - msg.value;

        require(wETH.approve(spender_, wETHAmount_));
        (bool success, ) = exchangeProxy.call{value: msg.value}(swapCallData_);
        if (success == false) {
            revert TokenSwapFailed(address(token_));
        }

        userRefundsAmount[user_] += address(this).balance - prevTotalRefundsAmount;
        uint256 boughtAmount = token_.balanceOf(address(this)) - prevTokenAmount;
        _userStrategyTokenBalance[user_][strategyId_][address(token_)] += boughtAmount;
        emit TokenBought(user_, strategyId_, address(token_), wETHAmount_, boughtAmount);
    }

    function setExchangeProxy(address exchangeProxy_) external onlyOwner {
        exchangeProxy = exchangeProxy_;
        emit ExchangeProxyChanged(exchangeProxy_);
    }

    function claimRefunds() external {
        uint256 refundAmount = userRefundsAmount[msg.sender];
        userRefundsAmount[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: refundAmount}("");
        if (success == false) {
            revert RefundClaimFailed();
        }
    }
}
