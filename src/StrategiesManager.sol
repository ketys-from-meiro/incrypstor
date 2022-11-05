// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IStrategiesManager.sol";
import "./interfaces/IApprovedTokens.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrategiesManager is IStrategiesManager, Ownable {
    struct Strategy {
        string name;
        mapping(address => uint8) tokenPercentage;
        address[] tokens;
    }

    uint8 public constant MAX_TOKENS_PER_STRATEGY_MIN_COUNT = 10;
    uint8 public constant MAX_STRATEGIES_PER_USER_MIN_COUNT = 5;
    uint8 public maxTokensPerStrategy = MAX_TOKENS_PER_STRATEGY_MIN_COUNT;
    uint8 public maxStrategiesPerUser = MAX_STRATEGIES_PER_USER_MIN_COUNT;
    IApprovedTokens public approvedTokens;
    mapping(address => mapping(uint256 => Strategy)) private _userStrategies;
    mapping(address => uint256[]) private _userStrategyIds;

    constructor(address approvedTokens_) {
        approvedTokens = IApprovedTokens(approvedTokens_);
    }

    function createStrategy(string calldata name_, IStrategiesManager.TokenParams[] memory tokensParams_)
        external
        returns (uint256)
    {
        uint256 userStrategiesCount = _userStrategyIds[msg.sender].length;
        if (userStrategiesCount >= maxStrategiesPerUser) {
            revert StrategiesLimitReached({maxCount: maxStrategiesPerUser});
        }
        if (tokensParams_.length >= maxTokensPerStrategy) {
            revert StrategyTokensLimitReached({maxCount: maxTokensPerStrategy});
        }

        uint256 newStrategyId = userStrategiesCount == 0
            ? 1
            : _userStrategyIds[msg.sender][userStrategiesCount - 1] + 1;
        _userStrategyIds[msg.sender].push(newStrategyId);
        Strategy storage newStrategy = _userStrategies[msg.sender][newStrategyId];
        newStrategy.name = name_;
        uint8 percentageSum;
        for (uint256 i = 0; i < tokensParams_.length; i++) {
            address tokenAddress = tokensParams_[i].addr;
            uint8 tokenPercentage = tokensParams_[i].percentage;
            if (!approvedTokens.isTokenApproved(tokenAddress)) {
                revert TokenNotApproved();
            }
            if (newStrategy.tokenPercentage[tokenAddress] != 0) {
                revert DuplicateToken();
            }
            percentageSum += tokenPercentage;
            newStrategy.tokenPercentage[tokenAddress] = tokenPercentage;
            newStrategy.tokens.push(tokenAddress);
        }
        if (percentageSum != 100) {
            revert StrategyTotalPercentageNotEq100();
        }
        emit StrategyCreated(msg.sender, newStrategyId);
        return newStrategyId;
    }

    function getYourStrategy(uint256 strategyId_) external view returns (IStrategiesManager.StrategyView memory) {
        Strategy storage strategy = _userStrategies[msg.sender][strategyId_];
        if (strategy.tokens.length == 0) {
            revert StrategyDoesNotExist();
        }
        return _transformStrategyToViewType(strategy);
    }

    function getYourStrategies() external view returns (IStrategiesManager.StrategyView[] memory) {
        uint256[] memory userStrategyIds = _userStrategyIds[msg.sender];
        IStrategiesManager.StrategyView[] memory strategyViews = new IStrategiesManager.StrategyView[](
            userStrategyIds.length
        );
        for (uint256 i = 0; i < userStrategyIds.length; i++) {
            Strategy storage strategy = _userStrategies[msg.sender][userStrategyIds[i]];
            strategyViews[i] = _transformStrategyToViewType(strategy);
        }
        return strategyViews;
    }

    function setMaxTokensPerStrategy(uint8 maxTokensPerStrategy_) external onlyOwner {
        if (maxTokensPerStrategy_ < MAX_TOKENS_PER_STRATEGY_MIN_COUNT) {
            revert InvalidMaxTokensPerStrategy({validMin: MAX_TOKENS_PER_STRATEGY_MIN_COUNT});
        }
        uint8 prevValue = maxTokensPerStrategy;
        maxTokensPerStrategy = maxTokensPerStrategy_;
        emit MaxTokensPerStrategyChanged(msg.sender, prevValue, maxTokensPerStrategy_);
    }

    function setMaxStrategiesPerUser(uint8 maxStrategiesPerUser_) external onlyOwner {
        if (maxStrategiesPerUser_ < MAX_STRATEGIES_PER_USER_MIN_COUNT) {
            revert InvalidMaxStrategiesPerUser({validMin: MAX_STRATEGIES_PER_USER_MIN_COUNT});
        }
        uint8 prevValue = maxStrategiesPerUser;
        maxStrategiesPerUser = maxStrategiesPerUser_;
        emit MaxStrategiesPerUserChanged(msg.sender, prevValue, maxStrategiesPerUser_);
    }

    function _transformStrategyToViewType(Strategy storage strategy)
        private
        view
        returns (IStrategiesManager.StrategyView memory)
    {
        IStrategiesManager.StrategyView memory strategyView;
        strategyView.name = strategy.name;
        strategyView.tokensParams = new IStrategiesManager.TokenParams[](strategy.tokens.length);
        for (uint256 i = 0; i < strategy.tokens.length; i++) {
            address tokenAddr = strategy.tokens[i];
            strategyView.tokensParams[i] = IStrategiesManager.TokenParams({
                addr: tokenAddr,
                percentage: strategy.tokenPercentage[tokenAddr]
            });
        }
        return strategyView;
    }

    // TODO:
    // modifyStrategy: respektuje count parametry a v pripade, ze user ma jiz vice strategii
    // nebo strategii s vice tokeny, tak nedovoli navysit pocet pokud jiz je pres limit
}
