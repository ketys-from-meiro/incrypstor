// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ApprovedTokens is Ownable {
    event TokenApproved(address indexed tokenAddress);
    event TokenRevoked(address indexed tokenAddress);

    error InvalidTokenAddress();
    error TokenAlreadyApproved();
    error TokenNotApproved();

    struct Token {
        string name;
        string symbol;
        address addr;
    }

    address[] public approvedTokenAddresses;
    mapping(address => bool) private _isTokenAddressApproved;

    function approveToken(address tokenAddress_) external onlyOwner {
        if (_isNullAddress(tokenAddress_) || tokenAddress_.code.length == 0) {
            // checking only if it's a contract, idk about a way to check if
            // the given address actually imlements ERC20
            revert InvalidTokenAddress();
        }
        if (_isTokenAddressApproved[tokenAddress_]) {
            revert TokenAlreadyApproved();
        }
        _isTokenAddressApproved[tokenAddress_] = true;
        approvedTokenAddresses.push(tokenAddress_);
        emit TokenApproved(tokenAddress_);
    }

    function revokeToken(uint256 index_) external onlyOwner {
        if (index_ >= approvedTokenAddresses.length) {
            revert TokenNotApproved();
        }
        address tokenAddress = approvedTokenAddresses[index_];
        _isTokenAddressApproved[tokenAddress] = false;
        _removeFromApprovedTokenAddressesArray(index_);
        emit TokenRevoked(tokenAddress);
    }

    function getApprovedTokenAddresses() public view returns (address[] memory) {
        address[] memory tokenAddresses;
        for (uint256 i = 0; i < approvedTokenAddresses.length; i++) {
            tokenAddresses[i] = approvedTokenAddresses[i];
        }
        return tokenAddresses;
    }

    /**
     * May not be used, we can fetch tokens metadata off-chain by using contract addresses only
     */
    function getApprovedTokens() public view returns (Token[] memory) {
        Token[] memory tokens;
        for (uint256 i = 0; i < approvedTokenAddresses.length; i++) {
            IERC20Metadata tokenMetadata = IERC20Metadata(approvedTokenAddresses[i]);
            Token memory token;
            token.addr = approvedTokenAddresses[i];
            token.name = tokenMetadata.name();
            token.symbol = tokenMetadata.symbol();
            tokens[i] = token;
        }
        return tokens;
    }

    function _removeFromApprovedTokenAddressesArray(uint256 index_) private {
        approvedTokenAddresses[index_] = approvedTokenAddresses[approvedTokenAddresses.length - 1];
        approvedTokenAddresses.pop();
    }

    function _isNullAddress(address addr) private pure returns (bool) {
        return addr == address(0);
    }
}
