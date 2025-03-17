const { expect } = require("chai");

describe("Escrow", function () {
    let Escrow, escrow;
    let buyer, seller, arbiter;
    const amount = ethers.utils.parseEther("1");

    beforeEach(async function () {
        [buyer, seller, arbiter] = await ethers.getSigners();
        Escrow = await ethers.getContractFactory("Escrow");
        escrow = await Escrow.deploy(amount, arbiter.address);
        await escrow.deployed();

        await escrow.connect(buyer).setSeller(seller.address);
    });

    it("should allow the buyer to deposit the correct amount", async function () {
        await escrow.connect(buyer).deposit({ value: amount });

        expect(await escrow.balances(buyer.address)).to.equal(amount);
    });

    it("should allow the seller to mark the item as shipped", async function () {
        await escrow.connect(buyer).deposit({ value: amount });

        await escrow.connect(seller).markShipped();

        expect(await escrow.shipped()).to.be.true;
    });

    it("should allow the buyer to release funds to the seller", async function () {
        await escrow.connect(buyer).deposit({ value: amount });

        await escrow.connect(seller).markShipped();

        const sellerInitialBalance = await ethers.provider.getBalance(seller.address);

        await escrow.connect(buyer).releaseFunds();

        expect(await escrow.balances(buyer.address)).to.equal(0);
        expect(await ethers.provider.getBalance(seller.address)).to.equal(sellerInitialBalance.add(amount));
    });

    it("should allow the buyer to cancel the transaction before shipment", async function () {
        await escrow.connect(buyer).deposit({ value: amount });

        const buyerInitialBalance = await ethers.provider.getBalance(buyer.address);

        await escrow.connect(buyer).cancelTransaction();

        expect(await escrow.balances(buyer.address)).to.equal(0);
        expect(await ethers.provider.getBalance(buyer.address)).to.be.closeTo(buyerInitialBalance, ethers.utils.parseEther("0.01"));
    });

    it("should allow the arbiter to resolve a dispute in favor of the buyer", async function () {
        await escrow.connect(buyer).deposit({ value: amount });

        const buyerInitialBalance = await ethers.provider.getBalance(buyer.address);

        await escrow.connect(arbiter).disputeResolution();

        expect(await escrow.balances(buyer.address)).to.equal(0);
        expect(await ethers.provider.getBalance(buyer.address)).to.be.closeTo(buyerInitialBalance, ethers.utils.parseEther("0.01"));
    });

    it("should allow the arbuter to resolve a dispute in favor of the seller", async function () {
        await escrow.connect(buyer).deposit({ value: amount });

        await escrow.connect(seller).markShipped();

        const sellerInitialBalance = await ethers.provider.getBalance(seller.address);

        await escrow.connect(arbiter).disputeResolution();

        expect(await escrow.balances(buyer.address)).to.equal(0);
        expect(await ethers.provider.getBalance(seller.address)).to.equal(sellerInitialBalance.add(amount));
    });

    it("should auto-release funds to the seller after the release time", async function () {
        await escrow.connect(buyer).deposit({ value: amount });

        await escrow.connect(seller).markShipped();

        const sellerInitialBalance = await ethers.provider.getBalance(seller.address);

        await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await escrow.connect(buyer).autoReleaseFunds();

        expect(await escrow.balances(buyer.address)).to.equal(0);
        expect(await ethers.provider.getBalance(seller.address)).to.equal(sellerInitialBalance.add(amount));
    });
});
