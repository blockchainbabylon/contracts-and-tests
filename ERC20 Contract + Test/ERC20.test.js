const { expect } = require("chai");

describe("ERC20Token", function () {
    let ERC20Token, token;
    let owner, addr1, addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        ERC20Token = await ethers.getContractFactory("ERC20");
        token = await ERC20Token.deploy(1000);
        await token.deployed();
    });

    it("should initialize everything correctly", async function () {
        expect(await token.name()).to.equal("Richard's Token");
        expect(await token.symbol()).to.equal("RTN");
        expect(await token.decimals()).to.equal(18);
        expect(await token.owner()).to.equal(owner.address);
    });

    it("should assign the total supply to the owner", async function () {
        expect(await token.totalSupply()).to.equal(1000 * 10 ** 18);
        expect(await token.balanceOf(owner.address)).to.equal(1000 * 10 ** 18);
    });

    it("should allow users to transfer tokens", async function () {
        await token.transfer(addr1.address, 100);
        expect(await token.balanceOf(addr1.address)).to.equal(100);
    });

    it("should emit Transfer event upon transfer", async function () {
        await expect(token.transfer(addr1.address, 100))
            .to.emit(token, "Transfer")
            .withArgs(owner.address, addr1.address, 100);
    });

    it("should allow users to approve spenders", async function () {
        await token.approve(addr1.address, 100);
        expect(await token.allowance(owner.address, addr1.address)).to.equal(200);
    });

    it("should allow approved spender to transfer tokens", async function () {
        await token.approve(addr1.address, 100);
        expect(await token.allowance(owner.address, addr1.address)).to.equal(100);

        await token.connect(addr1).transferFrom(owner.address, addr2.address, 100);
        expect(await token.balanceOf(addr2.address)).to.equal(100);
    });

    it("should emit Approval event on approve", async function () {
        await expect(token.approve(addr1.address, 100))
            .to.emit(token, "Approval")
            .withArgs(owner.address, addr1.address, 100);
    });

    it("should fail transferFrom if allowance is not enough", async function () {
        await expect(token.connect(addr1).transferFrom(owner.address, addr1.address, 100))
            .to.be.revertedWith("ERC20: transfer amount exceeds allowance");
    });

    it("should fail transfer if balance is not enough", async function () {
        await expect(token.connect(addr1).transfer(addr2.address, 100))
            .to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });
});