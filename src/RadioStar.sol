// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC1155/erc1155.sol";
import "openzeppelin-contracts/utils/Strings.sol";

contract RadioStar is ERC1155 {
    address public owner;
    uint256 public tokenId = 0;

    mapping(uint256 => address) private tokensToArtist;
    // TODO: mapping for tokenId to price for artist to be able to set price

    event RadioStarCreated(address artistAccount, uint256 tokenId);
    event RadioStarPurchased(address fanAccount, uint256 tokenId);

    constructor(string memory uri) ERC1155(uri) {
        _setURI(uri);
        owner = msg.sender;
    }

    // Function for an artist to create a RadioStar Song NFT for purchase
    function createRadioStar(uint256 supply) external {
        // TODO: set price
        _mint(owner, tokenId, supply, "");
        tokensToArtist[tokenId] = msg.sender;
        emit RadioStarCreated(msg.sender, tokenId);
        // tokenId is incremented to be the tokenId for next RadioStar
        tokenId++;
    }

    // Function for a fan to purchase a RadioStar Song NFT
    function mintRadioStar(uint256 _tokenId) external {
        // TODO: require payment
        address artistAccount = tokensToArtist[_tokenId];
        // TODO: send percentage of funds to artistAccount
        safeTransferFrom(owner, msg.sender, _tokenId, 1, "");
        emit RadioStarPurchased(msg.sender, _tokenId);
    }

    // TODO: Function for RadioStar owner to withdraw funds
}
