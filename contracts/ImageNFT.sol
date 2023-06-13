// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GRToken is ERC721 {
    using Counters for Counters.Counter;

    struct Token {
        string name;
        string description;
        uint256 price;
        string imageUrl;
    }

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => Token) private _tokens;

    constructor() ERC721("MyToken", "MTK") {}

    function mint(string memory name, string memory description, uint256 price, string memory imageUrl) public returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(msg.sender, tokenId);
        _tokens[tokenId] = Token(name, description, price, imageUrl);
        return tokenId;
    }

    function getToken(uint256 tokenId) public view returns (string memory, string memory, uint256, string memory) {
        require(_exists(tokenId), "Token does not exist");
        Token memory token = _tokens[tokenId];
        return (token.name, token.description, token.price, token.imageUrl);
    }

    function getTokenPrice(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        Token memory token = _tokens[tokenId];
        return token.price;
    }
}