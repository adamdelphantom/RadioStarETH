// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract RadioStar is ERC1155URIStorage {
    uint256 public constant PLATFORM_ROYALTY_PERCENT = 2;
    uint256 public constant SUPERFAN_ROYALITY_PERCENT = 3;
    address private _owner;
    // TokenId 0 will not be associated with a token
    uint256 public tokenId = 0;

    mapping(uint256 => address) public tokensToArtist;
    mapping(uint256 => uint256) public tokensToBuyPrice;
    mapping(address => uint256) public balances;
    mapping(address => uint256[]) public purchasedSongs;
    //new maps
    mapping(uint256 => uint256) public tokensToMintPrice; // for superfans
    mapping(address => mapping(uint256 => bool)) public hasBought;
    mapping(address => mapping(uint256 => bool)) public hasMinted;
    mapping(uint256 => uint256) public tokensToMintSupply; // only applicable for limited edition NFTs

    uint256 public platformRoyaltyCollected = 0;
    uint256 public superfanRoyaltyCollected = 0;

    event songCreated(
        address indexed artistAccount,
        uint256 indexed tokenId,
        uint256 supply,
        uint256 buyPrice,
        uint256 mintPrice
    );

    event songPurchased(address indexed fanAccount, uint256 indexed tokenId);
    event songMinted(address indexed superFanAccount, uint256 indexed tokenId);

    constructor() ERC1155("") {
        _owner = msg.sender;
    }

    // Function for an artist to create a RadioStar Song NFT for purchase
    // TODO: make this external when createRadioStar is removed
    function createSong(
        uint256 mintSupply,
        uint256 buyPrice,
        uint256 mintPrice,
        string memory uri
    ) external {
        require(
            buyPrice >= 10**6, // in gwei
            "listing price should be greater than 0.001 eth"
        );

        require(
            buyPrice >= 5 * 10**7, // in gwei
            "mint price should be greater than 0.05 eth"
        );

        tokenId++;
        tokensToArtist[tokenId] = msg.sender;
        tokensToBuyPrice[tokenId] = buyPrice;
        tokensToMintPrice[tokenId] = mintPrice;
        tokensToMintSupply[tokenId] = mintSupply; //only applicable for limited NFTs (superfans)

        ERC1155URIStorage._setURI(tokenId, uri);
        emit songCreated(msg.sender, tokenId, mintSupply, buyPrice, mintPrice);
    }

    // Deprecated: use createSong
    // function createRadioStar(uint256 supply, uint256 priceInGwei, string memory _uri) external {
    //     createSong(supply, priceInGwei, _uri);
    // }

    // Function for a fan to purchase a RadioStar Song NFT
    // TODO: make external when buyRadioStar is removed
    function buySong(uint256 _tokenId) external payable {
        require(
            tokensToArtist[_tokenId] != address(0),
            "the song doesnt exists"
        );
        require(
            tokensToBuyPrice[_tokenId] <= msg.value,
            "the price should be greater or equal to the listing price"
        );

        _mint(msg.sender, tokenId, 1, "");
        purchasedSongs[msg.sender].push(_tokenId);

        if (hasBought[msg.sender][_tokenId] == false) {
            hasBought[msg.sender][_tokenId] = true;
        }

        uint256 amountPaid = msg.value;
        uint256 platformRoyalty = (amountPaid * PLATFORM_ROYALTY_PERCENT) / 100;
        uint256 superfanRoyalty = (amountPaid * SUPERFAN_ROYALITY_PERCENT) /
            100;

        uint256 artistAmoundRemaining = amountPaid -
            (platformRoyalty + superfanRoyalty);
        balances[tokensToArtist[_tokenId]] += artistAmoundRemaining;
        platformRoyaltyCollected += platformRoyalty;
        emit songPurchased(msg.sender, _tokenId);
    }

    // Deprecated: use buySong
    // function buyRadioStar(uint256 _tokenId) external payable {
    //     buySong(_tokenId);
    // }

    //function to mint limited edition nfts for superfans
    function mintLimitedRadioStar(uint256 _tokenId) external payable {
        require(
            tokensToArtist[_tokenId] != address(0),
            "the song doesnt exists"
        );
        require(
            hasMinted[msg.sender][_tokenId] == false,
            "you can mint the song only once"
        );
        require(
            tokensToMintSupply[_tokenId] > 0,
            "No spots left for superfans"
        );

        require(
            tokensToMintPrice[_tokenId] <= msg.value,
            "the price should be greater or equal to the listing price"
        );

        //TODO: tokenId for Fan NFTs and Superfan NFTs are different. figire out how to associiate odd tokenids for fans and even tokenids for superfans
        _mint(msg.sender, tokenId, 1, "");
        tokensToMintSupply[_tokenId] -= 1;
        balances[tokensToArtist[_tokenId]] += msg.value;
        hasMinted[msg.sender][_tokenId] = true;
        emit songMinted(msg.sender, _tokenId);
    }

    function getPurchasedSongs(address purchaser)
        public
        view
        returns (uint256[] memory)
    {
        return purchasedSongs[purchaser];
    }

    //TODO: figure out how to distribute royalities to superfans.
    function withdraw() external {
        uint256 withdrawAmount;
        if (msg.sender == _owner) {
            withdrawAmount = platformRoyaltyCollected;
            platformRoyaltyCollected = 0;
        } else {
            withdrawAmount = balances[msg.sender];
            balances[msg.sender] = 0;
        }
        require(withdrawAmount >= 10000000, "Insufficient fund to withdraw.");
        (bool sent, ) = payable(msg.sender).call{value: withdrawAmount}("");
        require(sent, "Failed to transfer the balance");
    }

    receive() external payable {}
}
