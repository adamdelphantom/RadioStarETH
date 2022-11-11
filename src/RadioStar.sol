// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract RadioStar is ERC1155URIStorage {
    uint256 public constant PLATFORM_ROYALTY_PERCENT = 2;
    uint256 public constant SUPERFAN_ROYALTY_PERCENT = 3;
    address private _owner;
    // TokenId 0 will not be associated with a token
    uint256 public tokenId = 0;
    uint256[] public fanTokenIds;
    uint256[] public superFanTokenIds;

    mapping(uint256 => address) public tokensToArtist;
    mapping(uint256 => uint256) public tokensToFanPrice;
    mapping(uint256 => uint256) public tokensToSuperfanPrice; // for superfans
    mapping(uint256 => uint256) public tokensToSuperfanSupply; // only applicable for limited edition NFTs
    mapping(uint256 => uint256) public fanTokensToSuperFanTokens;

    mapping(address => uint256) public ethBalances;
    mapping(address => uint256[]) public purchasedSongs;
    mapping(address => uint256[]) public mintedSongs;
    mapping(address => mapping(uint256 => bool)) public hasPurchased;
    mapping(address => mapping(uint256 => bool)) public hasMinted;

    uint256 public platformRoyaltyCollected = 0;
    mapping(uint256 => uint256) superfanRoyaltyCollected; // tokenId to royalty
    address[] private superFans;

    event songCreated(
        address indexed artistAccount,
        uint256 indexed fanTokenId,
        uint256 indexed superFanTokenId,
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
    function createSong(
        uint256 fanPrice,
        string memory fanTokenUri,
        uint256 superFanSupply,
        uint256 superFanPrice,
        string memory superFanTokenUri
    ) external {
        require(
            fanPrice >= 10**6, // in gwei
            "listing price should be greater than 0.001 eth"
        );

        require(
            superFanPrice >= 5 * 10**7, // in gwei
            "mint price should be greater than 0.05 eth"
        );

        uint256 fanTokenId = tokenId;
        tokensToArtist[fanTokenId] = msg.sender;
        tokensToFanPrice[fanTokenId] = fanPrice;
        fanTokenIds.push(fanTokenId);
        ERC1155URIStorage._setURI(fanTokenId, fanTokenUri);

        tokenId += 1;

        uint256 superFanTokenId = tokenId;
        tokensToArtist[superFanTokenId] = msg.sender;
        tokensToSuperfanPrice[superFanTokenId] = superFanPrice;
        tokensToSuperfanSupply[superFanTokenId] = superFanSupply; //only applicable for limited NFTs (superfans)
        superFanTokenIds.push(superFanTokenId);
        ERC1155URIStorage._setURI(superFanTokenId, superFanTokenUri);

        fanTokensToSuperFanTokens[fanTokenId] = superFanTokenId;

        tokenId += 1;

        emit songCreated(
            msg.sender,
            fanTokenId,
            superFanTokenId,
            superFanSupply,
            fanPrice,
            superFanPrice
        );
    }

    // Function for a fan to purchase a RadioStar Song NFT
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

        uint256 amountPaid = msg.value;
        uint256 platformRoyalty = (amountPaid * PLATFORM_ROYALTY_PERCENT) / 100;
        uint256 superfanRoyalty = (amountPaid * SUPERFAN_ROYALTY_PERCENT) / 100;

        uint256 artistAmountRemaining = amountPaid -
            (platformRoyalty + superfanRoyalty);

        ethBalances[tokensToArtist[_tokenId]] += artistAmountRemaining;
        platformRoyaltyCollected += platformRoyalty;

        // TODO: change this to update balances of all superfan holders with royalties
        // instead of a lump sum
        superfanRoyaltyCollected[fanTokensToSuperFanTokens[_tokenId]] += superfanRoyalty;

        emit songPurchased(msg.sender, _tokenId);
    }

    //function to mint limited edition nfts for superfans
    function mintSuperfanNFT(uint256 _tokenId) external payable {
        require(
            tokensToArtist[fanTokensToSuperFanTokens[_tokenId]] != address(0),
            "the song doesn't exist"
        );
        require(
            hasMinted[msg.sender][fanTokensToSuperFanTokens[_tokenId]] == false,
            "you can mint the song only once"
        );
        require(
            tokensToSuperfanSupply[fanTokensToSuperFanTokens[_tokenId]] > 0,
            "No spots left for superfans"
        );
        require(
            tokensToSuperfanPrice[fanTokensToSuperFanTokens[_tokenId]] <=
                msg.value,
            "the price should be greater or equal to the listing price"
        );

        _mint(msg.sender, tokenId, 1, "");
        tokensToSuperfanSupply[fanTokensToSuperFanTokens[_tokenId]] -= 1;
        ethBalances[tokensToArtist[fanTokensToSuperFanTokens[_tokenId]]] += msg
            .value;
        hasMinted[msg.sender][fanTokensToSuperFanTokens[_tokenId]] = true;
        superFans.push(msg.sender);
        mintedSongs[msg.sender].push(fanTokensToSuperFanTokens[_tokenId]);
        emit songMinted(msg.sender, fanTokensToSuperFanTokens[_tokenId]);
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
            withdrawAmount = ethBalances[msg.sender];
            ethBalances[msg.sender] = 0;
        }
        require(withdrawAmount >= 10000000, "Insufficient fund to withdraw.");
        (bool sent, ) = payable(msg.sender).call{value: withdrawAmount}("");
        require(sent, "Failed to transfer the balance");
    }

    // need to check if caller is a superfan
    function withdrawSuperfan() external {
        require(mintedSongs[msg.sender].length != 0, "you are not a superfan");

        // send allocation to superfan holder
        (bool sent, ) = payable(msg.sender).call{value: royalty}("");
        require(sent, "Failed to transfer the royalities");
    }

    receive() external payable {}
}
