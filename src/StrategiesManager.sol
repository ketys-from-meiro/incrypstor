// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IStrategiesManager.sol";
import "./interfaces/IApprovedTokens.sol";
import "./interfaces/ITokensOperations.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StrategiesManager is IStrategiesManager, Ownable, ReentrancyGuard {
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
    ITokensOperations public tokensOperations;
    mapping(address => mapping(uint256 => Strategy)) private _userStrategy;
    mapping(address => uint256[]) private _userStrategyIds;

    constructor(address approvedTokens_, address tokensOperations_) {
        approvedTokens = IApprovedTokens(approvedTokens_);
        tokensOperations = ITokensOperations(tokensOperations_);
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
        Strategy storage newStrategy = _userStrategy[msg.sender][newStrategyId];
        newStrategy.name = name_;
        uint8 percentageSum;
        for (uint256 i = 0; i < tokensParams_.length; i++) {
            address tokenAddress = tokensParams_[i].addr;
            uint8 tokenPercentage = tokensParams_[i].percentage;
            if (tokenPercentage == 0) {
                revert InvalidZeroPercentage(tokenAddress);
            }
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

    function getUserStrategy(address address_, uint256 strategyId_)
        external
        view
        returns (IStrategiesManager.StrategyView memory)
    {
        Strategy storage strategy = _getUserStrategy(address_, strategyId_);
        return _transformStrategyToViewType(strategyId_, strategy);
    }

    function getUserStrategies(address address_) external view returns (IStrategiesManager.StrategyView[] memory) {
        uint256[] memory userStrategyIds = _userStrategyIds[address_];
        IStrategiesManager.StrategyView[] memory strategyViews = new IStrategiesManager.StrategyView[](
            userStrategyIds.length
        );
        for (uint256 i = 0; i < userStrategyIds.length; i++) {
            Strategy storage strategy = _userStrategy[address_][userStrategyIds[i]];
            strategyViews[i] = _transformStrategyToViewType(userStrategyIds[i], strategy);
        }
        return strategyViews;
    }

    // must send msg.value covering `amount_` deposit plus fees for 0x swaps (swapQuotes[].gasPrice)
    function investIntoYourStrategy(
        uint256 strategyId_,
        uint256 amount_,
        IStrategiesManager.ZeroXApiQuote[] calldata swapQuotes_
    ) external payable nonReentrant {
        Strategy storage strategy = _getUserStrategy(msg.sender, strategyId_);
        if (swapQuotes_.length != strategy.tokens.length) {
            revert SwapQuotesArrayLengthDoesntMatch();
        }
        tokensOperations.depositETH{value: amount_}(msg.sender, strategyId_);
        for (uint256 i = 0; i < swapQuotes_.length; i++) {
            address tokenAddress = swapQuotes_[i].token;
            if (strategy.tokenPercentage[tokenAddress] == 0) {
                revert UnknownTokenInSwapQuotes({token: tokenAddress});
            }
            uint256 amountToInvest = (amount_ / 100) * strategy.tokenPercentage[tokenAddress];
            tokensOperations.buyToken{value: swapQuotes_[i].gasPrice}(
                msg.sender,
                strategyId_,
                IERC20(tokenAddress),
                amountToInvest,
                swapQuotes_[i].spender,
                swapQuotes_[i].swapCallData
            );
        }
        emit StrategyInvestmentCompleted(msg.sender, strategyId_, block.timestamp, amount_);
    }

    function investIntoUserStrategy(
        address user_,
        uint256 strategyId_,
        uint256 amount_
    ) external payable nonReentrant {}

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

    function _transformStrategyToViewType(uint256 strategyId_, Strategy storage strategy)
        private
        view
        returns (IStrategiesManager.StrategyView memory)
    {
        IStrategiesManager.StrategyView memory strategyView;
        strategyView.id = strategyId_;
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

    function _getUserStrategy(address user_, uint256 strategyId_) private view returns (Strategy storage) {
        Strategy storage strategy = _userStrategy[user_][strategyId_];
        if (strategy.tokens.length == 0) {
            revert StrategyDoesNotExist();
        }
        return strategy;
    }
}
