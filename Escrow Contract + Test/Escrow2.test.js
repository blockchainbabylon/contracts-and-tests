const { expect } = require("chai");

describe("Escrow2", function () {
    let Escrow2, escrow;
    let buyer, seller, arbiter;
    let amount = ethers.utils.parseEther("1");

    beforeEach(async function () {
        [owner, seller, arbiter] = await ethers.getSigners();
        Escrow2 = await ethers.getContractFactory("Escrow2");
        escrow = await Escrow2.deploy(seller.address, arbiter.address, amount);
        await escrow.deployed();
    });

    it("Should initialize everything correctly", async function () {
        expect(await escrow.buyer()).to.equal(buyer.address);
        expect(await escrow.seller()).to.equal(seller.address);
        expect(await escrow.arbiter()).to.equal(arbiter.address);
        expect(await escrow.amount()).to.equal(amount);
        expect(await escrow.currentState()).to.equal(0);
    });

    it("Should allow only the buyer to deposit", async function () {
        await expect(escrow.connect(buyer).deposit(amount))
        .to.emit(escrow, "Deposit")
        .withArgs(buyer.address, amount);
        
        expect(await escrow.currentState()).to.equal(1);
        expect(await ethers.provider.getBalance(escrow.address)).to.equal(amount);
    });

    it("Should revert if user is not the buyer", async function () {
        await expect(escrow.connect(arbiter)).deposit(amount)
        .to.be.revertedWith("Only buyer can call this");
    });

    it("Should allow buyer to release funds to seller", async function () {
        await escrow.deposit({ value: amount });

        await expect(escrow.release())
            .to.emit(escrow, "Release")
            .withArgs(seller.address, amount);

        expect(await escrow.currentState()).to.equal(2);
        expect(await ethers.provider.getBalance(escrow.address)).to.equal(0);
    });

    it("Should allow the seller to refund the buyer", async function () {
        await escrow.deposit({ value: amount });

        await expect(escrow.connect(seller).refund())
            .to.emit(escrow, "Refund")
            .withArgs(buyer.address, amount);
        
        expect(await ethers.provider.getBalance(escrow.address)).to.equal(0);
        expect(await escrow.currentState()).to.equal(3)
    });

    it("Should allow the buyer to dispute the escrow", async function () {
        await escrow.deposit({ value: amount });

        await expect(escrow.dispute())
            .to.emit(escrow, "Dispute")
            .withArgs(arbiter.address, amount);

        expect(await escrow.currentState()).to.equal(4);
        expect(await escrow.isDisputed()).to.equal(true);
    });

    it("Should allow the arbiter to resolve the dispute in favor of the seller", async function () {
        await escrow.deposit({ value: amount });

        await escrow.dispute();

        await expect(escrow.connect(arbiter).resolveDispute(true))
            .to.emit(escrow, "ResolveDispute")
            .withArgs(arbiter.address, true);
        
        expect(await escrow.currentState()).to.equal(2);
        expect(await ethers.provider.getBalance(escrow.address)).to.equal(0);
    });

    it("Should allow the arbiter to resolve the dispute in favor of the buyer", async function () {
        await escrow.deposit({ value: amount });

        await escrow.dispute();

        await expect(escrow.connect(arbiter).resolveDispute(false))
            .to.emit(escrow, "ResolveDispute")
            .withArgs(arbiter.address, false);

        expect(await escrow.currentState()).to.equal(3);
        expect(await ethers.provider.getBalance(escrow.address)).to.equal(0);
    })
})