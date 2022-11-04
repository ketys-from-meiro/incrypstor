// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/ApprovedTokens.sol";
import "../src/interfaces/IApprovedTokens.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ApprovedTokensTest is Test {
    event TokenApproved(address indexed tokenAddress);
    event TokenRevoked(address indexed tokenAddress);

    ApprovedTokens public approvedTokens;
    address private owner = address(1);
    ERC20 private artemisToken;
    ERC20 private incrypstorToken;

    function setUp() public {
        vm.startPrank(owner);

        approvedTokens = new ApprovedTokens();
        artemisToken = new ERC20("Artemis", "ATM");
        incrypstorToken = new ERC20("InCrypstor", "ICR");

        vm.stopPrank();
    }

    function testApproveTokenRejectedByNonOwner() public {
        vm.startPrank(address(2));
        vm.expectRevert("Ownable: caller is not the owner");
        approvedTokens.approveToken(address(5));
    }

    function testApproveTokenRejectedOnNullAddress() public {
        vm.startPrank(owner);
        vm.expectRevert(IApprovedTokens.InvalidTokenAddress.selector);
        approvedTokens.approveToken(address(0));
    }

    function testApproveTokenRejectedOnNonContractAddress() public {
        vm.startPrank(owner);
        vm.expectRevert(IApprovedTokens.InvalidTokenAddress.selector);
        approvedTokens.approveToken(address(5));
    }

    function testApproveTokenPassing() public {
        vm.startPrank(owner);

        vm.expectEmit(true, false, false, false);
        emit TokenApproved(address(artemisToken));
        approvedTokens.approveToken(address(artemisToken));
        assertEq(approvedTokens.getApprovedTokenAddress(0), address(artemisToken));
        assertEq(approvedTokens.isTokenApproved(address(artemisToken)), true);

        vm.expectRevert(IApprovedTokens.TokenAlreadyApproved.selector);
        approvedTokens.approveToken(address(artemisToken));
    }

    function testRevokeTokenRejectedByNonOwner() public {
        vm.startPrank(address(2));
        vm.expectRevert("Ownable: caller is not the owner");
        approvedTokens.approveToken(address(5));
    }

    function testRevokeTokenIndexOutOfBounds() public {
        vm.startPrank(owner);
        vm.expectRevert(IApprovedTokens.IndexDoesNotExist.selector);
        approvedTokens.revokeToken(0);

        approvedTokens.approveToken(address(artemisToken));
        vm.expectRevert(IApprovedTokens.IndexDoesNotExist.selector);
        approvedTokens.revokeToken(1);
    }

    function testRevokeTokenPassing() public {
        vm.startPrank(owner);
        approvedTokens.approveToken(address(artemisToken));

        vm.expectEmit(true, false, false, false);
        emit TokenRevoked(address(artemisToken));
        approvedTokens.revokeToken(0);
        assertEq(approvedTokens.isTokenApproved(address(artemisToken)), false);
        vm.expectRevert();
        approvedTokens.getApprovedTokenAddress(0);
    }

    function testRevokeTokenPassingWithMoreAlreadyApprovedTokens() public {
        vm.startPrank(owner);
        approvedTokens.approveToken(address(artemisToken));
        approvedTokens.approveToken(address(incrypstorToken));

        vm.expectEmit(true, false, false, false);
        emit TokenRevoked(address(artemisToken));
        approvedTokens.revokeToken(0);
        assertEq(approvedTokens.isTokenApproved(address(artemisToken)), false);
        assertEq(approvedTokens.getApprovedTokenAddress(0), address(incrypstorToken));
    }

    function testGetApprovedTokenAddressesEmptySet() public {
        address[] memory tokenAddresses = approvedTokens.getApprovedTokenAddresses();
        assertEq(tokenAddresses.length, 0);
    }

    function testGetApprovedTokenAddresses() public {
        vm.startPrank(owner);
        approvedTokens.approveToken(address(artemisToken));
        approvedTokens.approveToken(address(incrypstorToken));
        vm.stopPrank();

        address[] memory tokenAddresses = approvedTokens.getApprovedTokenAddresses();
        assertEq(tokenAddresses.length, 2);
        assertEq(tokenAddresses[0], address(artemisToken));
        assertEq(tokenAddresses[1], address(incrypstorToken));
    }

    function testGetApprovedTokensEmptySet() public {
        ApprovedTokens.Token[] memory tokens = approvedTokens.getApprovedTokens();
        assertEq(tokens.length, 0);
    }

    function testGetApprovedTokens() public {
        vm.startPrank(owner);
        approvedTokens.approveToken(address(artemisToken));
        approvedTokens.approveToken(address(incrypstorToken));
        vm.stopPrank();

        ApprovedTokens.Token[] memory tokens = approvedTokens.getApprovedTokens();
        assertEq(tokens.length, 2);
        assertEq(
            keccak256(abi.encode(tokens[0])),
            keccak256(
                abi.encode(
                    IApprovedTokens.Token({
                        name: artemisToken.name(),
                        symbol: artemisToken.symbol(),
                        addr: address(artemisToken)
                    })
                )
            )
        );
        assertEq(
            keccak256(abi.encode(tokens[1])),
            keccak256(
                abi.encode(
                    IApprovedTokens.Token({
                        name: incrypstorToken.name(),
                        symbol: incrypstorToken.symbol(),
                        addr: address(incrypstorToken)
                    })
                )
            )
        );
    }

    function testGetApprovedToken() public {
        vm.startPrank(owner);
        approvedTokens.approveToken(address(artemisToken));
        vm.stopPrank();

        IApprovedTokens.Token memory token = approvedTokens.getApprovedToken(0);
        assertEq(
            keccak256(abi.encode(token)),
            keccak256(
                abi.encode(
                    IApprovedTokens.Token({
                        name: artemisToken.name(),
                        symbol: artemisToken.symbol(),
                        addr: address(artemisToken)
                    })
                )
            )
        );
    }
}
