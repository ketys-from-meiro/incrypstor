// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IApprovedTokens.sol";

contract ApprovedTokens is IApprovedTokens, Ownable {
    address[] private _approvedTokenAddresses;
    mapping(address => bool) private _isTokenApproved;

    function approveToken(address tokenAddress_) external onlyOwner {
        if (_isNullAddress(tokenAddress_) || tokenAddress_.code.length == 0) {
            // checking only if it's a contract, idk about a way to check if
            // the given address actually imlements ERC20
            revert InvalidTokenAddress();
        }
        if (_isTokenApproved[tokenAddress_]) {
            revert TokenAlreadyApproved();
        }
        _isTokenApproved[tokenAddress_] = true;
        _approvedTokenAddresses.push(tokenAddress_);
        emit TokenApproved(tokenAddress_);
    }

    function revokeToken(uint256 index_) external onlyOwner {
        if (index_ >= _approvedTokenAddresses.length) {
            revert IndexDoesNotExist();
        }
        address tokenAddress = _approvedTokenAddresses[index_];
        _isTokenApproved[tokenAddress] = false;
        _removeFromApprovedTokenAddressesArray(index_);
        emit TokenRevoked(tokenAddress);
    }

    function isTokenApproved(address addr_) external view returns (bool) {
        return _isTokenApproved[addr_];
    }

    function getApprovedTokenAddress(uint256 index_) external view returns (address) {
        return _approvedTokenAddresses[index_];
    }

    function getApprovedToken(uint256 index_) external view returns (Token memory) {
        IERC20Metadata tokenMetadata = IERC20Metadata(_approvedTokenAddresses[index_]);
        Token memory token;
        token.addr = _approvedTokenAddresses[index_];
        token.name = tokenMetadata.name();
        token.symbol = tokenMetadata.symbol();
        return token;
    }

    function getApprovedTokenAddresses() external view returns (address[] memory) {
        address[] memory tokenAddresses = new address[](_approvedTokenAddresses.length);
        for (uint256 i = 0; i < _approvedTokenAddresses.length; i++) {
            tokenAddresses[i] = _approvedTokenAddresses[i];
        }
        return tokenAddresses;
    }

    /**
     * May not be used, we can fetch tokens metadata off-chain using contract addresses only
     */
    function getApprovedTokens() external view returns (Token[] memory) {
        Token[] memory tokens = new Token[](_approvedTokenAddresses.length);
        for (uint256 i = 0; i < _approvedTokenAddresses.length; i++) {
            IERC20Metadata tokenMetadata = IERC20Metadata(_approvedTokenAddresses[i]);
            Token memory token;
            token.addr = _approvedTokenAddresses[i];
            token.name = tokenMetadata.name();
            token.symbol = tokenMetadata.symbol();
            tokens[i] = token;
        }
        return tokens;
    }

    function _removeFromApprovedTokenAddressesArray(uint256 index_) private {
        _approvedTokenAddresses[index_] = _approvedTokenAddresses[_approvedTokenAddresses.length - 1];
        _approvedTokenAddresses.pop();
    }

    function _isNullAddress(address addr) private pure returns (bool) {
        return addr == address(0);
    }
}
