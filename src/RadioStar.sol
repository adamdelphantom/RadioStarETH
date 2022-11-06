// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC1155/erc1155.sol";
import "openzeppelin-contracts/utils/Strings.sol";

contract RadioStar is ERC1155 {
    uint256 public tokenId = 0;

    mapping(address => uint256) private _artistTokenIds;

    event RadioStarCreated(address artistAccount, uint256 tokenId);
    event SongPurchased(address fanAccount, uint256 tokenId);

    // Sets base URI for RadioStar NFTs
    constructor(string memory uri_) ERC1155(uri_) {
        _setURI(uri_);
        owner = msg.sender;
    }
    
    // // TODO: Function for an artist to create a RadioStar Song NFT for purchase
    // function createRadioStar(uint256 supply) {
    //     // create token w/ supply parameter
    //     // increment tokenId
    //     // incremented tokenId is the tokenId for this radiostar
    //     // update _artistTokenIds w/ tokenId and msg.sender (artist)
    //     // emit RadioStarCreated event
    // }

    // Function for a fan to purchase a RadioStar Song NFT
    function mintRadioStar(uint256 tokenId) {
        // TODO: require payment
        _mint(msg.sender, tokenId, 1);
        _balances[tokenId][msg.sender] += 1;
        emit SongPurchased(msg.sender, tokenId);
    }

    // TODO: Function for an artist to withdraw funds

    // TODO: Function for RadioStar owner to withdraw funds

    // Overrides uri getter to produce OpenSea compatible uri string
    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                _uri,
                Strings.toString(tokenId),
                ".json"
            )
        );
    }
}
