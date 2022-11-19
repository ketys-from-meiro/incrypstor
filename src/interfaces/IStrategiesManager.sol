// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStrategiesManager {
    // --- STRUCTS ---
    // TODO: tokens decimals
    struct TokenParams {
        address addr;
        uint8 percentage;
    }

    struct TokenParamsView {
        address addr;
        uint8 percentage;
        uint256 holdings;
    }

    struct StrategyView {
        uint256 id;
        string name;
        TokenParamsView[] tokensParams;
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
    error InvalidZeroPercentage(address token);
    error TokenNotApproved();
    error DuplicateToken();
    error StrategyTotalPercentageNotEq100();
    error StrategyDoesNotExist();
    error UnknownTokenInSwapQuotes(address token);
    error StrategyWithdrawalFailed();

    // --- EVENTS ---
    event StrategyCreated(address indexed user, uint256 indexed strategyId);
    event StrategyClosed(address indexed user, uint256 indexed strategyId);
    event MaxTokensPerStrategyChanged(address indexed owner, uint8 prevValue, uint8 newValue);
    event MaxStrategiesPerUserChanged(address indexed owner, uint8 prevValue, uint8 newValue);
    event StrategyInvestmentCompleted(
        address indexed user,
        uint256 indexed strategyId,
        uint256 timestamp,
        uint256 amount
    );

    // --- FUNCTIONS ---
    function createStrategy(string calldata name_, TokenParams[] calldata tokensParams_) external returns (uint256);

    function getUserStrategy(address user_, uint256 strategyId_) external view returns (StrategyView memory);

    function getUserStrategies(address user_) external view returns (StrategyView[] memory);

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

    function closeStrategy(uint256 strategyId_, IStrategiesManager.ZeroXApiQuote[] calldata swapQuotes_)
        external
        payable;

    function setMaxTokensPerStrategy(uint8 maxTokensPerStrategy_) external;

    function setMaxStrategiesPerUser(uint8 maxStrategiesPerUser_) external;
}
