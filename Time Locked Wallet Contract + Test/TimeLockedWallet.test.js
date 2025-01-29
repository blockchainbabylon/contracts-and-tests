const { expect } = require("chai");

describe("TimeLockedWallet", function () {
    let TimeLockedWallet, timeLockedWallet;
    let owner, addr1, addr2;
    const depositAmount = ethers.utils.parseEther("1"); // 1 ETH
    const lockDuration = 60; // 60 seconds

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        TimeLockedWallet = await ethers.getContractFactory("TimeLockedWallet");
        timeLockedWallet = await TimeLockedWallet.deploy();
        await timeLockedWallet.deployed();
    });

    it("Should allow anyone to deposit", async function () {
        await expect(timeLockedWallet.connect(addr1).deposit(lockDuration, { value: depositAmount }))
            .to.emit(timeLockedWallet, "Deposited")
            .withArgs(addr1.address, depositAmount);

        const balance = await timeLockedWallet.checkBalance(addr1.address);
        expect(balance).to.equal(depositAmount);
    });

    it("Should allow user to withdraw after lock time", async function () {
        await timeLockedWallet.connect(addr1).deposit(lockDuration, { value: depositAmount });

        // Fast-forward time past lock duration
        await ethers.provider.send("evm_increaseTime", [lockDuration]);
        await ethers.provider.send("evm_mine");

        await expect(timeLockedWallet.connect(addr1).withdraw(depositAmount))
            .to.emit(timeLockedWallet, "Withdraw")
            .withArgs(addr1.address, depositAmount);

        const balanceAfter = await timeLockedWallet.checkBalance(addr1.address);
        expect(balanceAfter).to.equal(0);
    });

    it("Should allow user to get their balance", async function () {
        await timeLockedWallet.connect(addr1).deposit(lockDuration, { value: depositAmount });

        const balance = await timeLockedWallet.checkBalance(addr1.address);
        expect(balance).to.equal(depositAmount);
    });

    it("Should allow user to see their locked time", async function () {
        await timeLockedWallet.connect(addr1).deposit(lockDuration, { value: depositAmount });

        const lockTime = await timeLockedWallet.checkLockTime(addr1.address);
        expect(lockTime).to.be.greaterThan(0);
    });

    it("Should not allow withdrawal before lock time", async function () {
        await timeLockedWallet.connect(addr1).deposit(lockDuration, { value: depositAmount });

        await expect(timeLockedWallet.connect(addr1).withdraw(depositAmount))
            .to.be.revertedWith("Has not been enough time");
    });

    it("Should not allow withdrawal of more than deposited amount", async function () {
        await timeLockedWallet.connect(addr1).deposit(lockDuration, { value: depositAmount });

        await ethers.provider.send("evm_increaseTime", [lockDuration]);
        await ethers.provider.send("evm_mine");

        const overWithdraw = ethers.utils.parseEther("2"); // 2 ETH (more than deposited)

        await expect(timeLockedWallet.connect(addr1).withdraw(overWithdraw))
            .to.be.revertedWith("Not enough balance");
    });
});
