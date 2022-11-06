// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStrategiesManager {
    // --- STRUCTS ---
    struct TokenParams {
        address addr;
        uint8 percentage;
    }

    struct StrategyView {
        string name;
        TokenParams[] tokensParams;
    }

    struct ZeroXApiQuote {
        address token;
        address spender;
        bytes swapCallData;
        uint256 gasPrice;
    }

    // --- ERRORS ---
    error StrategiesLimitReached(uint8 maxCount);
    error StrategyTokensLimitReached(uint8 maxCount);
    error InvalidMaxTokensPerStrategy(uint8 validMin);
    error InvalidMaxStrategiesPerUser(uint8 validMin);
    error TokenNotApproved();
    error DuplicateToken();
    error StrategyTotalPercentageNotEq100();
    error StrategyDoesNotExist();
    error SwapQuotesArrayLengthDoesntMatch();
    error UnknownTokenInSwapQuotes(address token);

    // --- EVENTS ---
    event StrategyCreated(address indexed user, uint256 strategyId);
    event MaxTokensPerStrategyChanged(address indexed owner, uint8 prevValue, uint8 newValue);
    event MaxStrategiesPerUserChanged(address indexed owner, uint8 prevValue, uint8 newValue);
    event StrategyInvestmentCompleted(address indexed user, uint256 strategyId, uint256 amount);

    // --- FUNCTIONS ---
    function createStrategy(string calldata name_, TokenParams[] calldata tokensParams_) external returns (uint256);

    function getYourStrategy(uint256 strategyId_) external view returns (StrategyView memory);

    function getYourStrategies() external view returns (StrategyView[] memory);

    function investIntoYourStrategy(
        uint256 strategyId_,
        uint256 amount_,
        IStrategiesManager.ZeroXApiQuote[] calldata swapQuotes_
    ) external payable;

    function investIntoUserStrategy(
        address user_,
        uint256 strategyId_,
        uint256 amount_
    ) external payable;

    function setMaxTokensPerStrategy(uint8 maxTokensPerStrategy_) external;

    function setMaxStrategiesPerUser(uint8 maxStrategiesPerUser_) external;
}
