// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract RadioStarFactory {
    mapping(address => mapping(address => address)) public RadioStarsToSongNFTs;
    // this mapping structure is insufficient
    // we need to map artist to multiple instances of
    // superfanNFT => songNFT

    // we could do something like this and trust that that
    // index of the superFan and song nfts stays aligned
    // smells bad
    struct Artist {
        address owner;
        address[] superFanNFTs;
        address[] songNFTs;
    }

    // then we'd have and array of artists:
    Artist[] artists;

    address public owner; // owner will receive revshare of all nfts created via factory

    // SongCreated event not sure of parameters to emit, yet

    constructor() {
        owner = msg.sender;
    }

    // CreateSong() creates contracts for superfan nfts and unlimited song nfts
    function DeploySong() public {
        // parameters:
        // address owner = msg.sender - can call withdraw on superfannft and song nft
        // address charity - to receive percentage
        // uint how many superfan nfts
        // uint percentage to owner
        // uint percentage to superfan holders
        // uint percentage to charity

        // emit SongCreated event

        // return token contract addresses? maybe not necessary
    }
}
