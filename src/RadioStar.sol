// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract RadioStar {
    address public owner;
    string public uri;

    constructor(address _owner, string memory _uri) {
        owner = _owner;
        uri = _uri;
    }
}