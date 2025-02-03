const { expect } = require("chai");

describe("SimpleERC20", function () {
    let Token, token;
    let owner, addr1;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        Token = await ethers.getContractFactory("SimpleERC20");
        token = await Token.deploy(ethers.utils.parseEther("1000"));
        await token.deployed();
    });

    it("Should have the correct name and symbol", async function () {
        expect(await token.name()).to.equal("SimpleToken");
        expect(await token.symbol()).to.equal("STK");
    });

    it("Should assign the initial supply to the owner", async function () {
        const ownerBalance = await token.balanceOf(owner.address);
        expect(ownerBalance).to.equal(ether.utils.parseEther("1000"));
    });

    it("Should allow minting new tokens", async function () {
        await token.mint(addr1.address, ethers.utils.parseEther("100"));
        const balance = await token.balanceOf(addr1.address);
        expect(balance).to.equal(ethers.utils.parseEther("100"));
    });

    it("Should transfer tokens between accounts", async function () {
        await token.transfer(addr1.address, ethers.utils.parseEther("50"));
        const addr1Balance = await token.balanceOf(addr1.address);
        expect(addr1Balance).to.equal(ethers.utils.parseEther("50"));
    });

    it("Should fail if sender does not have enough balance", async function () {
        const initialOwnerbalance = await token.balanceOf(owner.address);
        await expect(
            token.connect(addr1).transfer(owner.address, ethers.utils.parseEther("1"))
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

        expect(await token.balanceOf(owner.address)).to.equal(initialBalance);
    });
});