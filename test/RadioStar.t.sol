// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/RadioStar.sol";

contract RadioStarTest is Test {
    RadioStar radioStar;
    address radioStarOwner = address(0x1);
    address radioStarArtist = address(0x2);
    address radioStarFan = address(0x3);

    event RadioStarCreated(
        address indexed artistAccount,
        uint256 indexed tokenId,
        uint256 supply,
        uint256 priceInGwei
    );
    event RadioStarPurchased(address indexed fanAccount, uint256 indexed tokenId);
    
    function setUp() public {
        vm.prank(radioStarOwner);
        radioStar = new RadioStar("https://whatever/");
    }

    function testCreateRadioStar() public {
        vm.startPrank(radioStarArtist);
        uint256 _supply = 100;
        uint256 _priceInGwei = 20000000;

        assertEq(0, uint(radioStar.tokenId()), "Token Id not initialized to 0");
        
        vm.expectEmit(true, true, true, true);
        emit RadioStarCreated(radioStarArtist, 1, _supply, _priceInGwei);

        radioStar.createRadioStar(_supply, _priceInGwei);

        assertEq(radioStar.tokensToArtist(1), radioStarArtist, "TokenId not mapped to Artist's Account");
        assertEq(radioStar.tokensToPrice(1), _priceInGwei, "tokenId not mapped to price");
        assertEq(1, uint(radioStar.tokenId()), "Token ID not incremented");
        vm.stopPrank();
    }

    function testMintRadioStar() public {
        vm.startPrank(radioStarArtist);
        uint256 _supply = 100;
        uint256 _priceInGwei = 20000000;
        radioStar.createRadioStar(_supply, _priceInGwei);
        vm.stopPrank();

        vm.deal(radioStarFan, 10000e18);
        vm.startPrank(radioStarFan);

        vm.expectEmit(true, true, true, true); 
        emit RadioStarPurchased(radioStarFan, 1);

        radioStar.mintRadioStar{value: _priceInGwei}(1);
        vm.stopPrank();
    }
}
