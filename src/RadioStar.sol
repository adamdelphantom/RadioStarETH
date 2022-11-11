// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract RadioStar is ERC1155URIStorage {
    uint256 public constant PLATFORM_ROYALTY_PERCENT = 2;
    uint256 public constant SUPERFAN_ROYALITY_PERCENT = 3;
    address private _owner;
    // TokenId 0 will not be associated with a token
    uint256 currentFanTokenId = 1;
    uint256 currentSuperfanTokenId = 2;
    uint256 public tokenId = 0;

    mapping(uint256 => address) public tokensToArtist;
    mapping(uint256 => uint256) public tokensToFanPrice;
    mapping(address => uint256) public balances;
    mapping(address => uint256[]) public purchasedSongs;
    //new maps
    mapping(uint256 => uint256) public tokensToSuperfanPrice; // for superfans
    mapping(address => mapping(uint256 => bool)) public hasPurchased;
    mapping(address => mapping(uint256 => bool)) public hasMinted;
    mapping(uint256 => uint256) public tokensToSuperfanSupply; // only applicable for limited edition NFTs

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
        uint256 superfanSupply,
        uint256 fanPrice,
        uint256 superfanPrice,
        string memory uri
    ) external {
        require(
            fanPrice >= 10**6, // in gwei
            "listing price should be greater than 0.001 eth"
        );

        require(
            superfanPrice >= 5 * 10**7, // in gwei
            "mint price should be greater than 0.05 eth"
        );

        tokensToArtist[currentSuperfanTokenId] = msg.sender;
        tokensToFanPrice[currentSuperfanTokenId] = fanPrice;
        tokensToSuperfanPrice[currentSuperfanTokenId] = superfanPrice;
        tokensToSuperfanSupply[currentSuperfanTokenId] = superfanSupply; //only applicable for limited NFTs (superfans)
        currentSuperfanTokenId += 2;

        ERC1155URIStorage._setURI(tokenId, uri);
        emit songCreated(msg.sender, tokenId, superfanSupply, fanPrice, superfanPrice);
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
            tokensToFanPrice[_tokenId] <= msg.value,
            "the price should be greater or equal to the fan price"
        );

        _mint(msg.sender, tokenId, 1, "");
        purchasedSongs[msg.sender].push(_tokenId);

        if (hasPurchased[msg.sender][_tokenId] == false) {
            hasPurchased[msg.sender][_tokenId] = true;
        }

        uint256 amountPaid = msg.value;
        uint256 platformRoyalty = (amountPaid * PLATFORM_ROYALTY_PERCENT) / 100;
        uint256 superfanRoyalty = (amountPaid * SUPERFAN_ROYALITY_PERCENT) / 100;

        uint256 artistAmoundRemaining = amountPaid - (platformRoyalty + superfanRoyalty);

        balances[tokensToArtist[_tokenId]] += artistAmoundRemaining;
        platformRoyaltyCollected += platformRoyalty;
        emit songPurchased(msg.sender, _tokenId);
    }

    // Deprecated: use buySong
    // function buyRadioStar(uint256 _tokenId) external payable {
    //     buySong(_tokenId);
    // }

    //function to mint limited edition nfts for superfans
    function mintSuperfanNFT(uint256 _songTokenId) external payable {
        uint256 superfanTokenId = _songTokenId+1;
        require(
            tokensToArtist[_songTokenId] != address(0),
            "the song doesn't exist"
        );
        require(
            hasMinted[msg.sender][superfanTokenId] == false,
            "you can mint the song only once"
        );
        require(
            tokensToSuperfanSupply[superfanTokenId] > 0,
            "No spots left for superfans"
        );
        require(
            tokensToSuperfanPrice[superfanTokenId] <= msg.value,
            "the price should be greater or equal to the listing price"
        );

        //TODO: tokenId for Fan NFTs and Superfan NFTs are different. figire out how to associiate odd tokenids for fans and even tokenids for superfans
        _mint(msg.sender, tokenId, 1, "");
        tokensToSuperfanSupply[superfanTokenId] -= 1;
        balances[tokensToArtist[_songTokenId]] += msg.value;
        hasMinted[msg.sender][superfanTokenId] = true;
        emit songMinted(msg.sender, superfanTokenId);
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
