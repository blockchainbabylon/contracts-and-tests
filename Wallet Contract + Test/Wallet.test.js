const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Wallet Contract", function () {
    let Wallet, wallet, owner, addr1;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        Escrow = await ethers.getContractFactory("Wallet");
        escrow = await Wallet.deploy();
        await escrow.depoyed();
    });

    it("Should set the correct owner", async function () {
        expect(await wallet.owner()).to.equal(owner.address);
    });

    it ("Should allow the owner to deposit", async function () {
        await wallet.deposit({ value: ethers.utils.parseEther("1.0") });
        expect(await ethers.providers.getBalance(wallet.address)).to.equal(ethers.utils.parseEther(1.0));
    });

    it("Should allow the owner to withdraw", async function () {
        await wallet.deposit({ value: ethers.utils.parseEther("1.0") });
        await wallet.withdraw(ethers.utils.parseEther("1.0"));
        expect(await ethers.providers.getBalance(wallet.address)).to.equal(0);
    });

    it ("Should not allow non-owners to withdraw", async function () {
        await wallet.deposit({ value: ethers.utils.parseEther("1.0") });
        await expect(wallet.connect(addr1).withdraw(ethers.utils.parseEther("1.0")));
    });

    it ("Should not allow the withdraw if balance is insufficient", async function () {
        await expect(wallet.withdraw(ethers.utils.parseEther("1.0"))).to.be.revertedWith("Insufficient balance");
    });
});