// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./RadioStar.sol";

contract RadioStarFactory {

    address public owner;

    mapping(address => address[]) public artistsToRadioStars;

    constructor() {
        owner = msg.sender;
    }

    function CreateRadioStar(address artist, string memory uri) public {
        RadioStar radioStar = new RadioStar(artist, uri);
    }
}
