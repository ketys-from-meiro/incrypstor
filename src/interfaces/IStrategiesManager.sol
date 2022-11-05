// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStrategiesManager {
    // --- STRUCTS ---
    struct TokenParams {
        address addr;
        uint8 percentage;
    }

    // --- ERRORS ---
    error StrategiesLimitReached(uint8 maxCount);
    error StrategyTokensLimitReached(uint8 maxCount);
    error InvalidMaxTokensPerStrategy(uint8 validMin);
    error InvalidMaxStrategiesPerUser(uint8 validMin);
    error TokenNotApproved();
    error DuplicateToken();
    error StrategyTotalPercentageNotEq100();

    // --- EVENTS ---
    event StrategyCreated(address indexed investor, uint256 strategyId);
    event MaxTokensPerStrategyChanged(address indexed owner, uint8 prevValue, uint8 newValue);
    event MaxStrategiesPerUserChanged(address indexed owner, uint8 prevValue, uint8 newValue);

    // --- FUNCTIONS ---
    function createStrategy(string calldata name_, TokenParams[] calldata tokensParams_) external returns (uint256);

    function setMaxTokensPerStrategy(uint8 maxTokensPerStrategy_) external;

    function setMaxStrategiesPerUser(uint8 maxStrategiesPerUser_) external;
}
