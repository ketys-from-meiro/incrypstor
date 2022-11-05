// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/ApprovedTokens.sol";
import "../src/StrategiesManager.sol";
import "../src/interfaces/IStrategiesManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StrategiesManagerTest is Test {
    event StrategyCreated(address indexed investor, uint256 strategyId);
    event MaxTokensPerStrategyChanged(address indexed owner, uint8 prevValue, uint8 newValue);
    event MaxStrategiesPerUserChanged(address indexed owner, uint8 prevValue, uint8 newValue);

    StrategiesManager public strategiesManager;
    ApprovedTokens public approvedTokens;
    address private owner = address(1);
    ERC20 private artemisToken;
    ERC20 private incrypstorToken;
    ERC20 private wethToken;

    function setUp() public {
        vm.startPrank(owner);

        approvedTokens = new ApprovedTokens();
        artemisToken = new ERC20("Artemis", "ATM");
        incrypstorToken = new ERC20("InCrypstor", "ICR");
        wethToken = new ERC20("Wrapper Ether", "wETH");
        approvedTokens.approveToken(address(wethToken));
        approvedTokens.approveToken(address(artemisToken));
        approvedTokens.approveToken(address(incrypstorToken));

        strategiesManager = new StrategiesManager(address(approvedTokens));

        vm.stopPrank();
    }

    function testCanCreateStrategies() public {
        vm.startPrank(address(2));
        uint256 strategyId = 1;
        IStrategiesManager.TokenParams[] memory tokensParams = _createTokensParamsForSuccessCall();
        vm.expectEmit(true, false, false, true);
        emit StrategyCreated(address(2), strategyId);
        uint256 createdStrategyId = strategiesManager.createStrategy("AllIn Shitcoins", tokensParams);
        assertEq(strategyId, createdStrategyId);

        strategyId = 2;
        vm.expectEmit(true, false, false, true);
        emit StrategyCreated(address(2), strategyId);
        createdStrategyId = strategiesManager.createStrategy("Max yield", tokensParams);
        assertEq(strategyId, createdStrategyId);
        vm.stopPrank();

        vm.startPrank(address(3));
        strategyId = 1;
        vm.expectEmit(true, false, false, true);
        emit StrategyCreated(address(3), strategyId);
        createdStrategyId = strategiesManager.createStrategy("Ape", tokensParams);
        assertEq(strategyId, createdStrategyId);
    }

    function testCannotCreateMoreStrategiesThanMaxStrategiesPerUser() public {
        vm.startPrank(address(2));
        uint8 maxStrategiesPerUser = strategiesManager.maxStrategiesPerUser();
        IStrategiesManager.TokenParams[] memory tokensParams = _createTokensParamsForSuccessCall();
        for (uint8 i = 0; i < maxStrategiesPerUser; i++) {
            strategiesManager.createStrategy("", tokensParams);
        }
        vm.expectRevert(
            abi.encodeWithSelector(IStrategiesManager.StrategiesLimitReached.selector, maxStrategiesPerUser)
        );
        strategiesManager.createStrategy("Strategy above limit", tokensParams);
    }

    function testCannotCreateStrategyWithMoreTokensThanMaxTokensPerStrategy() public {
        vm.startPrank(address(2));
        uint8 maxTokensPerStrategy = strategiesManager.maxTokensPerStrategy();
        IStrategiesManager.TokenParams[] memory tokensParams = new IStrategiesManager.TokenParams[](
            maxTokensPerStrategy + 1
        );
        for (uint8 i = 0; i <= maxTokensPerStrategy; i++) {
            tokensParams[i] = IStrategiesManager.TokenParams({addr: address(artemisToken), percentage: 5});
        }
        vm.expectRevert(
            abi.encodeWithSelector(IStrategiesManager.StrategyTokensLimitReached.selector, maxTokensPerStrategy)
        );
        strategiesManager.createStrategy("Strategy with more tokens than allowed", tokensParams);
    }

    function testCannotCreateStrategyWithNotApprovedToken() public {
        vm.startPrank(address(2));
        IStrategiesManager.TokenParams[] memory tokensParams = new IStrategiesManager.TokenParams[](1);
        tokensParams[0] = IStrategiesManager.TokenParams({addr: address(25), percentage: 100});
        vm.expectRevert(IStrategiesManager.TokenNotApproved.selector);
        strategiesManager.createStrategy("Strategy with not allowed token", tokensParams);
    }

    function testCannotCreateStrategyWithDuplicateTokens() public {
        vm.startPrank(address(2));
        IStrategiesManager.TokenParams[] memory tokensParams = new IStrategiesManager.TokenParams[](3);
        tokensParams[0] = IStrategiesManager.TokenParams({addr: address(artemisToken), percentage: 50});
        tokensParams[1] = IStrategiesManager.TokenParams({addr: address(incrypstorToken), percentage: 25});
        tokensParams[2] = IStrategiesManager.TokenParams({addr: address(artemisToken), percentage: 25});
        vm.expectRevert(IStrategiesManager.DuplicateToken.selector);
        strategiesManager.createStrategy("Duplicate token in strategy", tokensParams);
    }

    function testCannotCreateStrategyWithTotalPercentageDifferentThan100() public {
        vm.startPrank(address(2));
        IStrategiesManager.TokenParams[] memory tokensParams = new IStrategiesManager.TokenParams[](2);
        tokensParams[0] = IStrategiesManager.TokenParams({addr: address(artemisToken), percentage: 50});
        tokensParams[1] = IStrategiesManager.TokenParams({addr: address(incrypstorToken), percentage: 49});
        vm.expectRevert(IStrategiesManager.StrategyTotalPercentageNotEq100.selector);
        strategiesManager.createStrategy("Strategy with 99%", tokensParams);
        tokensParams[1].percentage = 51;
        vm.expectRevert(IStrategiesManager.StrategyTotalPercentageNotEq100.selector);
        strategiesManager.createStrategy("Strategy with 101%", tokensParams);
    }

    function testSetMaxTokensPerStrategyRejectedByNonOwner() public {
        vm.startPrank(address(2));
        vm.expectRevert("Ownable: caller is not the owner");
        strategiesManager.setMaxTokensPerStrategy(12);
    }

    function testSetMaxTokensPerStrategyRejectedBelowMinCount() public {
        vm.startPrank(owner);
        uint8 minValue = strategiesManager.MAX_TOKENS_PER_STRATEGY_MIN_COUNT();
        vm.expectRevert(abi.encodeWithSelector(IStrategiesManager.InvalidMaxTokensPerStrategy.selector, minValue));
        strategiesManager.setMaxTokensPerStrategy(minValue - 1);
    }

    function testSetMaxTokensPerStrategyPassing() public {
        vm.startPrank(owner);
        uint8 defaultValue = strategiesManager.MAX_TOKENS_PER_STRATEGY_MIN_COUNT();
        vm.expectEmit(true, false, false, true);
        emit MaxTokensPerStrategyChanged(owner, defaultValue, 15);
        strategiesManager.setMaxTokensPerStrategy(15);
        assertEq(strategiesManager.maxTokensPerStrategy(), 15);
    }

    function testSetMaxStrategiesPerUserRejectedByNonOwner() public {
        vm.startPrank(address(2));
        vm.expectRevert("Ownable: caller is not the owner");
        strategiesManager.setMaxStrategiesPerUser(10);
    }

    function testSetMaxStrategiesPerUserRejectedBelowMinCount() public {
        vm.startPrank(owner);
        uint8 minValue = strategiesManager.MAX_STRATEGIES_PER_USER_MIN_COUNT();
        vm.expectRevert(abi.encodeWithSelector(IStrategiesManager.InvalidMaxStrategiesPerUser.selector, minValue));
        strategiesManager.setMaxStrategiesPerUser(minValue - 1);
    }

    function testSetMaxStrategiesPerUserPassing() public {
        vm.startPrank(owner);
        uint8 defaultValue = strategiesManager.MAX_STRATEGIES_PER_USER_MIN_COUNT();
        vm.expectEmit(true, false, false, true);
        emit MaxStrategiesPerUserChanged(owner, defaultValue, 10);
        strategiesManager.setMaxStrategiesPerUser(10);
        assertEq(strategiesManager.maxStrategiesPerUser(), 10);
    }

    // --- PRIVATE REUSABLE FUNCTIONS ---

    function _createTokensParamsForSuccessCall() private view returns (IStrategiesManager.TokenParams[] memory) {
        IStrategiesManager.TokenParams[] memory tokensParams = new IStrategiesManager.TokenParams[](2);
        tokensParams[0] = IStrategiesManager.TokenParams({addr: address(artemisToken), percentage: 25});
        tokensParams[1] = IStrategiesManager.TokenParams({addr: address(incrypstorToken), percentage: 75});
        return tokensParams;
    }
}
