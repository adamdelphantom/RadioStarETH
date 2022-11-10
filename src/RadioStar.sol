// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract RadioStar is ERC1155URIStorage{

    uint256 public constant PLATFORM_ROYALTY_PERCENT = 2;

    address private _owner;
    // TokenId 0 will not be associated with a token
    uint256 public tokenId = 0;

    mapping(uint256 => address) public tokensToArtist;
    mapping(uint256 => uint256) public tokensToPrice;
    mapping(address => uint256) public balances;
    mapping(address => uint256[]) public purchasedSongs; 
     uint256 public royaltyCollected = 0;

    event RadioStarCreated(
        address indexed artistAccount,
        uint256 indexed tokenId,
        uint256 supply,
        uint256 priceInGwei
    );
    event RadioStarPurchased(
        address indexed fanAccount,
        uint256 indexed tokenId
    );

    constructor() ERC1155("") {
        _owner = msg.sender;
    }

    // Function for an artist to create a RadioStar Song NFT for purchase
    // TODO: make this external when createRadioStar is removed
    function createSong(uint256 supply, uint256 priceInGwei, string memory _uri) public {
        require(
            priceInGwei >= 10000000,
            "listing price should be greater than 0.01 eth"
        );
        tokenId++;
        tokensToArtist[tokenId] = msg.sender;
        tokensToPrice[tokenId] = priceInGwei;
        ERC1155URIStorage._setURI(tokenId, _uri);
        emit RadioStarCreated(msg.sender, tokenId, supply, priceInGwei);
    }

    // Deprecated: use createSong
    function createRadioStar(uint256 supply, uint256 priceInGwei, string memory _uri) external {
        createSong(supply, priceInGwei, _uri);
    }

    // Function for a fan to purchase a RadioStar Song NFT
    // TODO: make external when buyRadioStar is removed
    function buySong(uint256 _tokenId) public payable {
        require(
            tokensToArtist[_tokenId] != address(0),
            "the song doesnt exists"
        );
        require(
            tokensToPrice[_tokenId] <= msg.value,
            "the price should be greater or equal to the listing price"
        );
        // TODO: Add supply check here
        _mint(msg.sender, tokenId, 1, "");
        purchasedSongs[msg.sender].push(_tokenId);
        uint256 amountPaid = msg.value;
        uint256 platformRoyalty = amountPaid * PLATFORM_ROYALTY_PERCENT / 100;
        uint256 artistAmoundRemaining = amountPaid - platformRoyalty;
        balances[tokensToArtist[_tokenId]] += artistAmoundRemaining;
        royaltyCollected += platformRoyalty;

        emit RadioStarPurchased(msg.sender, _tokenId);
    }

      // Deprecated: use buySong
    function buyRadioStar(uint256 _tokenId) external payable {
        buySong(_tokenId);
    }

    function getPurchasedSongs(address purchaser) public view returns (uint256[] memory) {
        return purchasedSongs[purchaser];
    }

    function withdraw() external {

        uint256 withdrawAmount;
        if (msg.sender == _owner) {
            withdrawAmount = royaltyCollected;
            royaltyCollected = 0;
        } else {
           
            withdrawAmount = balances[msg.sender];
            balances[msg.sender] = 0;
        }
        require(
                withdrawAmount >= 10000000,
                "Insufficient fund to withdraw."
            );
        (bool sent, ) = payable(msg.sender).call{value: withdrawAmount}("");
        require(sent, "Failed to transfer the balance");

    }

    receive() external payable {}
}
