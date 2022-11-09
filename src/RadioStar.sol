// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract RadioStar is ERC1155 {
    address private _owner;
    // TokenId 0 will not be associated with a token
    uint256 public tokenId = 0;

    mapping(uint256 => address) public tokensToArtist;
    mapping(uint256 => uint256) public tokensToPrice;
    mapping(address => uint256) public balances;

    event RadioStarCreated(
        address indexed artistAccount,
        uint256 indexed tokenId,
        uint256 supply,
        uint256 priceInGwei
    );
    event RadioStarPurchased(address indexed fanAccount, uint256 indexed tokenId);

    constructor() ERC1155("") {
        _owner = msg.sender;
    }

    // Function for an artist to create a RadioStar Song NFT for purchase
    function createRadioStar(uint256 supply, uint256 priceInGwei) external {
        require(
            priceInGwei >= 10000000,
            "listing price should be greater than 0.01 eth"
        );
        tokenId++;
        tokensToArtist[tokenId] = msg.sender;
        tokensToPrice[tokenId] = priceInGwei;
        emit RadioStarCreated(
            msg.sender,
            tokenId,
            supply,
            priceInGwei
        );
    }

    // Function for a fan to purchase a RadioStar Song NFT
    function buyRadioStar(uint256 _tokenId) external payable {
        require(
            tokensToPrice[_tokenId] <= msg.value,
            "the price should be greater or equal to the listing price"
        );       
        // TODO: Add supply check here
        _mint(msg.sender, tokenId, 1, "");
        balances[tokensToArtist[_tokenId]] += msg.value;
        emit RadioStarPurchased(msg.sender, _tokenId);
    }

    receive() external payable {}
}