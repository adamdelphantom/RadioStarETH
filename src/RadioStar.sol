// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/contract/token/ERC1155/erc1155.sol";

contract RadioStar is ERC1155 {
    address public owner;
    string public uri;

    constructor(address _owner, string memory _uri) {
        owner = _owner;
        uri = _uri;
    }
}