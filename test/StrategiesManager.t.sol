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

    // TODO: test create strategy function!

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
}
