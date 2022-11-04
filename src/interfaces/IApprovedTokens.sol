// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IApprovedTokens {
    // --- STRUCTS ---
    struct Token {
        string name;
        string symbol;
        address addr;
    }

    // --- EVENTS ---
    event TokenApproved(address indexed tokenAddress);
    event TokenRevoked(address indexed tokenAddress);

    // --- ERRORS ---
    error InvalidTokenAddress();
    error TokenAlreadyApproved();
    error IndexDoesNotExist();

    // --- FUNCTIONS ---
    function isTokenApproved(address addr_) external view returns (bool);

    function approveToken(address tokenAddress_) external;

    function revokeToken(uint256 index_) external;

    function getApprovedTokenAddress(uint256 index_) external view returns (address);

    function getApprovedToken(uint256 index_) external view returns (Token memory);

    function getApprovedTokenAddresses() external view returns (address[] memory);

    function getApprovedTokens() external view returns (Token[] memory);
}
