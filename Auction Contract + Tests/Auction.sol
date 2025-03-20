//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract DecentralizedAuction {
    struct Auction {
        address seller;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool finalized;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;
    uint256 public auctionCount;

    event AuctionCreated(uint256 auctionId, address seller, uint256 endTime);
    event NewBid(uint256 auctionId, address bidder, uint256 amount);
    event AuctionFinalized(uint256 auctionId, address winner, uint256 amount);

    function createAuction(uint256 durationInMinutes) external returns(uint256) {
        require(durationInMinutes > 0, "Duration must be greater than 0");

        auctionCount++;
        uint256 auctionId = auctionCount;

        auctions[auctionId] = Auction({
            seller: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + (durationInMinutes * 1 minutes),
            highestBid: 0,
            highestBidder: address(0),
            finalized: false
        });

        emit AuctionCreated(auctionId, msg.sender, auctions[auctionId].endTime);
        return auctionId;
    }

    function placeBid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid must be higher than current highest bid");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        bids[auctionId][msg.sender] += msg.value;

        emit NewBid(auctionId, msg.sender, msg.value);
    }

    function finalizeAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Auction is still ongoing");
        require(!auction.finalized, "Auction already finalized"); //auction cannot be already finalized
        require(msg.sender == auction.seller, "Only seller or highest bidder can finalize");

        auction.finalized = true;

        if (auction.highestBidder != address(0)) {
            payable(auction.seller).transfer(auction.highestBid);
            emit AuctionFinalized(auctionId, auction.highestBidder, auction.highestBid);
        }
    }

    function getAuctionDetails(uint256 auctionId) external view returns (
        address seller, uint256 startTime, uint256 endTime, uint256 highestBid, address highestBidder, bool finalized
    ) {
        Auction storage auction = auctions[auctionId];
        return (auction.seller, auction.startTime, auction.endTime, auction.highestBid, auction.highestBidder, auction.finalized);
    }
}
