// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract RadioStar is ERC1155 {

    uint256 immutable DEFAULT_PRICE = 0.3 ether;

    address public owner;
    uint256 public tokenId = 0;
    uint256 public artistCount = 0;

    struct Artist {
        uint256 id;
        string name;
        bool deleted;
    }

    struct Song {
        string title;
        uint256 price;
        uint256 tokenId;
        address artist;
        bool deleted;
    }

    mapping(uint256 => address) private tokensToArtist;
    mapping(address => Artist) private artists;
    mapping(uint256 => Song) private songs;

    event RadioStarCreated(address artistAccount, uint256 tokenId);
    event RadioStarPurchased(address fanAccount, uint256 tokenId);

    constructor(string memory uri) ERC1155(uri) {
        _setURI(uri);
        owner = msg.sender;
    }

    function registerArtist(string memory _name) external {
        artists[msg.sender] = Artist(artistCount, _name, false);
        artistCount++;
    }

    function createSong(string memory title, uint256 price) external {
        require(artists[msg.sender].id > 0, "Artist not known. Call registerArtist first.");
        songs[tokenId] = Song(title, price, tokenId, msg.sender, false);

        // Tell observers about a new token
        emit TransferSingle(msg.sender, address(0), address(0), tokenId, 0);

        tokenId++;
    }

    // Function for an artist to create a RadioStar Song NFT for purchase
    function createNFT(uint256 supply) external {
        // TODO: set price
        _mint(owner, tokenId, supply, "");
        tokensToArtist[tokenId] = msg.sender;
        emit RadioStarCreated(msg.sender, tokenId);
        // tokenId is incremented to be the tokenId for next RadioStar
        tokenId++;
    }

    // Function for a fan to purchase a RadioStar Song NFT
    function purchaseNFT(uint256 _tokenId) external {
        // TODO: require payment
        address artistAccount = tokensToArtist[_tokenId];
        // TODO: send percentage of funds to artistAccount
        safeTransferFrom(owner, msg.sender, _tokenId, 1, "");
        emit RadioStarPurchased(msg.sender, _tokenId);
    }

    // TODO: Function for RadioStar owner to withdraw funds
}
