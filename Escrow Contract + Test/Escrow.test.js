const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Escrow", function () {
    let escrow;
    let buyer;
    let seller;
    let arbiter;
    let amount = ethers.utils.parseEther("1");

    beforeEach(async function () {
        [buyer, seller, arbiter] = await ethers.getSigners();
        const Escrow = await ethers.getContractFactory("Escrow");
        escrow = await escrow.deploy(seller.address, arbiter.address);
    });

    it ("Should allow buyer to deposit funds", async function () {
        await escrow.connect(buyer).deposit({ value: amount });
        const balance = await escrow.balance();
        expect(balance).to.equal(amount);
    });

    it("Should allow the buyer to approve the transaction", async function () {
        await escrow.connect(buyer).deposit({ value: amount });
        await escrow.connect(buyer).approveByBuyer();
        const buyerApproval = await escrow.buyerApproved();
        expect(buyerApproval).to.be.true;
    });

    it("Should allow the seller to approve the transaction", async function () {
        await escrow.connect(buyer).deposit({ value: amount });
        await escrow.connect(seller).approveBySeller();
        const sellerApproval = await escrow.sellerApproved();
        expect(sellerApproval).to.be.true;
    });

    it ("Should release funds to the seller when both parties approve", async function () {
        await escrow.connect(buyer).deposit({ value: amount });
        
        await escrow.connect(buyer).approveByBuyer();
        const buyerApproval = await escrow.buyerApproved();
        expect(buyerApproval).to.be.true;
        
        await escrow.connect(seller).approveBySeller();
        const sellerApproval = await escrow.sellerApproved();
        expect(sellerApproval).to.be.true;

        await expect(() => escrow.connect(arbiter).release()).to.changeEtherbalances([seller, escrow], [amount, -amount]);
    });

    it("Should refund the buyer if both parties do not approve", async function () {
        await escrow.connect(buyer).deposit({ value: amount });
        await escrow.connect(buyer).approveByBuyer();

        await expect(() => escrow.connect(arbiter).refund()).to.changeEtherBalances([buyer, escrow], [amount, -amount]);
    });

    it("Should emit events correctly", async function () {
        await expect(escrow.connect(buyer).deposit({ value: amount })).to.emit(escrow, "Deposit").withArgs(buyer.address, amount);

        await escrow.connect(buyer).approveByBuyer();
        await expect(escrow.connect(buyer).approveByBuyer()).to.emit(escrow, "Approved").withArgs(buyer.address);
    
        await escrow.connect(arbiter).release();
        await expect(escrow.connect(arbiter).release()).to.emit(escrow, "Released").withArgs(arbiter.address, amount);
    });
});