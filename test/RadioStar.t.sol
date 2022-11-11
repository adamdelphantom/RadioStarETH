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
        radioStar = new RadioStar();
    }

    function testCreateSong() public {
        vm.startPrank(radioStarArtist);
        uint256 _supply = 100;
        uint256 _fanPriceInGwei = 20000000;
        uint256 _superfanPriceInGwei = 100000000;

        assertEq(0, uint(radioStar.tokenId()), "Token Id not initialized to 0");
        
        vm.expectEmit(true, true, true, true);
        emit RadioStarCreated(radioStarArtist, 1, _supply, _fanPriceInGwei);

        radioStar.createSong(_fanPriceInGwei, "", _supply, _superfanPriceInGwei, "");

        assertEq(radioStar.tokensToArtist(1), radioStarArtist, "TokenId not mapped to Artist's Account");
        assertEq(radioStar.tokensToFanPrice(1), _fanPriceInGwei, "tokenId not mapped to price");
        assertEq(1, uint(radioStar.tokenId()), "Token ID not incremented");
        vm.stopPrank();
    }

    function setupPurchase(uint256 _supply, uint256 _fanPriceInGwei, uint256 _superfanPriceInGwei) internal {
        vm.startPrank(radioStarArtist);
        radioStar.createSong(_fanPriceInGwei, "", _supply, _superfanPriceInGwei, "");
        vm.stopPrank();

        vm.deal(radioStarFan, _fanPriceInGwei+1);
    }

    function testBuySong() public {
        uint256 TOKEN_PRICE = 1000000 gwei;
        setupPurchase(100, TOKEN_PRICE, TOKEN_PRICE*5);

        uint256 royaltyBeforePurchase = radioStar.platformRoyaltyCollected();
        uint256 fanBalanceBefore = radioStarFan.balance;
        uint256 artistBalanceBefore = radioStar.ethBalances(radioStarArtist);

        vm.expectEmit(true, true, true, true);
        emit RadioStarPurchased(radioStarFan, 1);

        vm.startPrank(radioStarFan);
   
        radioStar.buySong{value: TOKEN_PRICE}(1);

        uint256 priceMinusRoyalty = TOKEN_PRICE - platformRoyaltyAmount(TOKEN_PRICE);
        assertEq(radioStar.ethBalances(radioStarArtist), artistBalanceBefore+priceMinusRoyalty, "artistBalance"); 

        console.log("Fan balance after ", radioStarFan.balance)  ;  

        assertEq(fanBalanceBefore-radioStarFan.balance, TOKEN_PRICE, "fanBalance");   

        assertEq(radioStar.platformRoyaltyCollected(), royaltyBeforePurchase+platformRoyaltyAmount(TOKEN_PRICE), "royaltyCollected");
        
        vm.stopPrank();  
    }
    
    function testBuySong_value_too_low_fail() public {
        uint256 TOKEN_PRICE = 20000000;
        setupPurchase(100, TOKEN_PRICE, TOKEN_PRICE*2);

        vm.deal(radioStarFan, 2*TOKEN_PRICE);
        vm.startPrank(radioStarFan);

        vm.expectRevert();
        radioStar.buySong{value: TOKEN_PRICE-1}(1);
    }

    function platformRoyaltyAmount(uint256 amount) internal view returns (uint256) {
        return amount * radioStar.PLATFORM_ROYALTY_PERCENT() / 100;
    }

    function testArtistCanWithdraw() public {
        uint256 TOKEN_PRICE = 0.01 ether;
        setupPurchase(100, TOKEN_PRICE, TOKEN_PRICE*2);

        uint256 artistBalanceBefore = radioStarArtist.balance;

        vm.startPrank(radioStarFan);   
        radioStar.buySong{value: TOKEN_PRICE}(1);
        vm.stopPrank();

        uint creditAmount = TOKEN_PRICE - platformRoyaltyAmount(TOKEN_PRICE);

        vm.startPrank(radioStarArtist);
        radioStar.withdraw();
        vm.stopPrank();
 
        assertEq(radioStarArtist.balance, artistBalanceBefore+creditAmount); 
    }

    function testOwnerCanWithdraw() public {
        uint256 TOKEN_PRICE = 0.01 ether;
        setupPurchase(100, TOKEN_PRICE, TOKEN_PRICE*2);

        vm.startPrank(radioStarFan);   
        radioStar.buySong{value: TOKEN_PRICE}(1);
        vm.stopPrank();

        uint256 royalty = platformRoyaltyAmount(TOKEN_PRICE);
        assertEq(radioStar.platformRoyaltyCollected(), royalty, "contractRoyalty");
        assertEq(radioStarOwner.balance, 0, "ownerBalance should start at 0"); 

        vm.startPrank(radioStarOwner);
        radioStar.withdraw();
        vm.stopPrank();
 
        assertEq(radioStarOwner.balance, royalty, "ownerRoyalty should increment by royalty"); 
        assertEq(radioStar.platformRoyaltyCollected(), 0, "royaltyCollected should be zero after withdrawal"); 
    }

}
