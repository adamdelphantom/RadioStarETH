// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/utils/Strings.sol";
import "@openzeppelin/utils/Base64.sol";

contract RadioStar is ERC1155 {
    address private _owner;
    // TokenId 0 will not be associated with a token
    uint256 public tokenId = 0;

    mapping(uint256 => address) public tokensToArtist;
    mapping(uint256 => uint256) public tokensToPrice;
    mapping(address => uint256) public balances;
    mapping(address => string) public artistName;
    mapping(uint256 => string) public songName;

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
    function createRadioStar(string calldata _artistName, 
        string calldata _songName,
        uint256 _supply, 
        uint256 _priceInGwei) external {
        require(
            _priceInGwei >= 10000000,
            "listing price should be greater than 0.01 eth"
        );
        tokenId++;
        tokensToArtist[tokenId] = msg.sender;
        tokensToPrice[tokenId] = _priceInGwei;
        songName[tokenId] = _songName;
        artistName[msg.sender] = _artistName;
        emit RadioStarCreated(
            msg.sender,
            tokenId,
            _supply,
            _priceInGwei
        );
    }

    // Function for a fan to purchase a RadioStar Song NFT
    function buyRadioStar(uint256 _tokenId) external payable {
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
        balances[tokensToArtist[_tokenId]] += msg.value;
        emit RadioStarPurchased(msg.sender, _tokenId);
    }

    function withdraw() external {
        require(
            balances[msg.sender] >= 10000000,
            "you don't have much balance, sell more songs!"
        );
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to transfer the balance");
    }

    receive() external payable {}

    function uri(uint256 _tokenId) override public view returns (string memory) {
        string memory trackName = songName[tokenId];
        string memory description = string.concat(trackName, " by ", artistName[tokensToArtist[_tokenId]]);
        string[5] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = "** RadioStar **";
        parts[2] = '</text><text x="10" y="40" class="base">';
        parts[3] = description;
        parts[4] = '</text></svg>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        trackName,
                        '", "description": "',
                        description,
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
}
