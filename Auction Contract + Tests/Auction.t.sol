//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/Auction.sol";

contract DecentralizedAuction is Test {
    DecentralizedAuction auctionContract;
    address seller = address(0x123);
    address bidder1 = address(0x456);
    address bidder2 = address(0x789);

    function setUp() public {
        auctionContract = new DecentralizeAuction();
        vm.deal(seller, 10 ether);
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);
    }

    function testCreateAuction() public {
        vm.prank(seller);
        uint256 auctionId = auctionContract.createAuction(10); //10 minutes

        (
            address auctionSeller,
            uint256 startTime,
            uint256 endTime,
            uint256 highestBid,
            address highestBidder,
            bool finalized
        ) = auctionContract.getAuctionDetails(auctionId);

        assertEq(auctionSeller, seller);
        assertTrue(startTime > 0);
        assertTrue(endTime > startTime);
        assertEq(highestBid, 0);
        assertEq(highestBidder, address(0));
        assertFalse(finalized);
    }

    function testPlaceBid() public {
        vm.prank(seller);
        uint256 auctionId = auctionContract.createAuction(10);

        vm.prank(bidder1);
        auctionContract.placeBid{value: 1 ether}(auctionId);

        (
            ,
            ,
            ,
            uint256 highestBid,
            address highestBidder,
        ) = auctionContract.getAuctionDetials(auctionId);

        assertEq(highestBid, 1 ether);
        assertEq(highestBidder, bidder1);
    }

    function testOutbid() public {
        vm.prank(seller);
        uint256 auctionId = auctionContract.createAuction(10);

        vm.prank(bidder1);
        auctionContract.placeBid{value: 1 ether}(auctionId);

        uint256 bidder1InitialBalance = bidder1.balance;

        vm.prank(bidder2);
        auctionContract.placeBid{value: 2 ether}(auctionId);

        (
            ,
            ,
            ,
            uint256 highestBid,
            address highestBidder,
        ) = auctionContract.getAuctionDetails(auctionId);

        assertEq(highestBid, 2 ether);
        assertEq(highestBidder, bidder2);
        assertEq(bidder1.balance, bidder1InitialBalance + 1 ether); //refund to bidder1
    }

    function testFinalizeAuction() public {
        vm.prank(seller);
        uint256 auctionId = auctionContract.createAuction(10);

        vm.prank(bidder1);
        auctionContract.placeBid{value: 1 ether}(auctionId);

        vm.warp(block.timestamp + 10 minutes);

        uint256 sellerInitialBalance = seller.balance;

        vm.prank(seller);
        auctionContract.finalizeAuction(auctionId);

        (
            ,
            ,
            ,
            ,
            ,
            bool finalized
        ) = auctionContract.getAuctionDetails(auctionId);

        assertTrue(finalized);
        assertEq(seller.balance, sellerInitialBalance + 1 ether);
    }

    function testCannotPlaceBidAfterAuctionEnds() public {
        vm.prank(seller);
        uint256 auctionId = auctionContract.createAuction(10);

        vm.warp(block.timestamp + 10 minutes); //fast forward 10 mintues

        vm.prank(bidder1);
        vm.expectRevert("Auction has ended");
        auctionContract.placeBid{value: 1 ether}(auctionId);
    }

    function testCannotFinalizeAuctionBeforeEndTime() public {
        vm.prank(seller);
        uint256 auctionId = auctionContract.createAuction(10);

        vm.prank(seller);
        vm.expectRevert("Auction is still ongoing");
        auctionContract.finalizeAuction(auctionId);
    }

    function testCannotFinalizeAuctionTwice() public {
        vm.prank(seller);
        uint256 auctionId = auctionContract.createAuction(10);

        vm.prank(bidder1);
        auctionContract.placeBid{value: 1 ether}(auctionId);

        vm.warp(block.timestamp + 10 minutes); //fast forward 10 minutes

        vm.prank(seller);
        auctionContract.finalizeAuction(auctionId);

        vm.prank(seller);
        vm.expectRevert("Auction already finalized");
        auctionContract.finalizeAuction(auctionId);
    }
}
