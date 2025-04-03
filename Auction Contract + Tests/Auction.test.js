const { expect } = require("chai");

describe("DecentralizedAuction", function () {
    let DecentralizedAuction, auctionContract;
    let owner, bidder1, bidder2;

    beforeEach(async function () {
        [owner, bidder1, bidder2] = await ethers.getSigners();
        DecentralizedAuction = await ethers.getContractFactory("DecentralizedAuction");
        auctionContract = await DecentralizedAuction.deploy();
        await auctionContract.deployed();
    });

    it("should allow a user to create an auction", async function () {
        const durationInMinutes = 10;

        const tx = await auctionContract.connect(owner).createAuction(durationInMinutes);
        const receipt = await tx.wait();
        const auctionId = receipt.events[0].args.auctionId;

        const auction = await auctionContract.getAuctionDetails(auctionId);

        expect(auction.seller).to.equal(owner.address);
        expect(auction.highestBid).to.equal(0);
        expect(auction.highestBidder).to.equal(ethers.constants.AddressZero);
        expect(auction.finalized).to.be.false;
        expect(auction.endTime).to.be.gt((await ethers.provider.getBlock("latest")).timestamp);
    });

    it("should allow users to place bids", async function () {
        const durationInMinutes = 10;

        const tx = await auctionContract.connect(owner).createAuction(durationInMinutes);
        const receipt = await tx.wait();
        const auctionId = receipt.events[0].args.auctionId;

        await auctionContract.connect(bidder1).placeBid(auctionId, { value: ethers.utils.parseEther("1") });

        const auction = await auctionContract.getAuctionDetails(auctionId);
        expect(auction.highestBid).to.equal(ethers.utils.parseEther("1"));
        expect(auction.highestBidder).to.equal(bidder1.address);
    });

    it("should refund the previous highest bidder when a new bid is placed", async function () {
        const durationInMinutes = 10;

        const tx = await auctionContract.connect(owner).createAuction(durationInMinutes);
        const receipt = await tx.wait();
        const auctionId = receipt.events[0].args.auctionId;

        await auctionContract.connect(bidder1).placeBid(auctionId, { value : ethers.utils.parseEther("1") });

        const bidder1InitialBalance = await ethers.provider.getBalance(bidder1.address);

        await auctionContract.connect(bidder2).placeBid(auctionId, { value: ethers.utils.parseEther("2") });

        const bidder1FinalBalance = await ethers.provider.getBalance(bidder1.address);
        expect(bidder1FinalBalance).to.be.closeTo(
            bidder1InitialBalance.add(ethers.utils.parseEther("1")),
            ethers.utils.parseEther("0.01")
        );

        const auction = await auctionContract.getAuctionDetials(auctionId);
        expect(auction.highestBid).to.equal(ethers.utils.parseEther("2"));
        expect(auction.highestBidder).to.equal(bidder2.address);
    });

    it("should not allow bids lower than the current highest bid", async function () {
        const durationInMinutes = 10;

        const tx = await auctionContract.connect(owner).createAuction(durationInMinutes);
        const receipt = await tx.wait();
        const auctionId = receipt.events[0].args.auctionId;

        await auctionContract.connect(bidder1).placeBid(auctionId, { value: ethers.utils.parseEther("1") });

        await expect(
            auctionContract.connect(bidder2).placeBid(auctionId, { value: ethers.utils.parseEther("0.5") })
        ).to.be.revertedWith("Bid must be higher than current highest bid");
    });

    it("should allow the seller to finalize the auction after it ends", async function () {
        const durationInMinutes =  1;

        const tx = await auctionContract.connect(owner).createAuction(durationInMinutes);
        const receipt = await tx.wait();
        const auctionId = receipt.events[0].args.auctionId;

        await auctionContract.connect(bidder1).placeBid(auctionId, { value: ethers.utils.parseEther("1") });

        await ethers.provider.send("evm_increaseTime", [60 * durationInMinutes]);
        await ethers.provider.send("evm_mine");

        const sellerInitialBalance = await ethers.provider.getBalance(owner.address);

        await auctionContract.connect(owner).finalizeAuction(auctionId);

        const sellerFinalBalance = await ethers.provider.getBalance(owner.address);
        expect(sellerFinalBalance).to.be.closeTo(
            sellerInitialBalance.add(ethers.utils.parseEther("1")),
            ethers.utils.parseEther("0.01")
        );

        const auction = await auctionContract.getAuctionDetails(auctionId);
        expect(auction.finalized).to.be.true;
    });

    it("should not allow finalizing an auction before it ends", async function () {
        const durationInMinutes = 10;

        const tx = await auctionContract.connect(owner).createAuction(durationInMinutes);
        const receipt = await tx.wait();
        const auctionId = receipt.events[0].args.auctionId;

        await auctionContract.connect(bidder1).placeBid(auctionId, { value: ethers.utils.parseEther("1") });

        await expect(auctionContract.connect(owner).finalizeAuction(auctionId)).to.be.revertedWith(
            "Auction is still ongoing"
        );
    });

    it("should not allow finalizing an auction twice", async function () {
        const durationInMinutes = 1;

        const tx = await auctionContract.connect(owner).createAuction(durationInMinutes);
        const receipt = await tx.wait();
        const auctionId = receipt.events[0].args.auctionId;

        await auctionContract.connect(bidder1).placeBid(auctionId, { value: ethers.utils.parseEther("1") });

        await ethers.provider.send("evm_increaseTime", [60 * durationInMinutes]);
        await ethers.provider.send("evm_mine");

        await auctionContract.connect(owner).finalizeAuction(auctionId);

        await expect(auctionContract.connect(owner).finalizeAuction(auctionId)).to.be.revertedWith(
            "Auction already finalized"
        );
    });
});
