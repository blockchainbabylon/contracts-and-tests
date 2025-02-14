const { expect } = require("chai");

describe("YieldVault", function () {
    let YieldVault, vault;
    let owner, user;
    const depositAmount = ethers.utils.parseEther("1");

    beforeEach(async function () {
        [owner, user] = await ethers.getSigners();
        YieldVault = await ethers.getContractFactory("YieldVault");
        vault = await YieldVault.deploy();
        await vault.deployed();
    });

    it("should allow user to deposit ETH", async function () {
        await vault.connect(user).deposit({ value: depositAmount });

        const deposit = await vault.deposits(user.address);
        expect(deposit.amount).to.equal(depositAmount);
        expect(deposit.unlockTime).to.be,greaterThan(0);
        expect(deposit.claimed).to.equal(false);
    });

    it("should not allow withdrawal before unlock time", async function () {
        await vault.connect(user).deposit({ value: depositAmount });

        await expect(vault.connect(user).withdraw()).to.be.revertedWith("Funds are locked");
    });

    it("should allow withdrawal after lock period", async function () {
        await vault.connect(user).deposit({ value: depositAmount });

        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        const yieldEarned = depositAmount.mul(5).div(100);
        const expectedPayout = depositAmount.add9yieldEarned;

        await expect(() => vault.connect(user).withdraw()).to.changeEtherBalance(user, expectedPayout);
    });

    it("should prevent double withdrawals", async function () {
        await vault.connect(user).deposit({ value: depositAmount });

        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await vault.connect(user).withdraw();

        await expect(vault.connect(user).withdraw()).to.be.revertedWith("Already withdrawn");
    })
})