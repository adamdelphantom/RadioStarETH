// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC1155/erc1155.sol";

contract RadioStar is ERC1155 {
    address public owner;
    uint256 public tokenId = 0;

    mapping(uint256 => address) public tokensToArtist;
    mapping(uint256 => uint256) private tokensToPrice;

    event RadioStarCreated(address artistAccount, uint256 tokenId, uint256 supply, uint256 priceInHundredthsOfEther);
    event RadioStarPurchased(address fanAccount, uint256 tokenId);

    constructor(string memory uri) ERC1155(uri) {
        _setURI(uri);
        owner = msg.sender;
    }

    // Function for an artist to create a RadioStar Song NFT for purchase
    function createRadioStar(uint256 supply, uint256 priceInHundredthsOfEther) external {
        tokenId++;
        tokensToArtist[tokenId] = msg.sender;
        tokensToPrice[tokenId] = priceInHundredthsOfEther;
        _mint(owner, tokenId, supply, "");
        emit RadioStarCreated(msg.sender, tokenId, supply, priceInHundredthsOfEther);
    }

    // Function for a fan to purchase a RadioStar Song NFT
    function mintRadioStar(uint256 _tokenId) external payable {
        uint256 songPrice = tokensToPrice[_tokenId];
        // TODO: require payment to >= songPrice
        address artistAccount = tokensToArtist[_tokenId];
        // TODO: send 2% of funds to owner
        // TODO: send remainer of funds to artistAccount
        safeTransferFrom(owner, msg.sender, _tokenId, 1, "");
        emit RadioStarPurchased(msg.sender, _tokenId);
    }
}
