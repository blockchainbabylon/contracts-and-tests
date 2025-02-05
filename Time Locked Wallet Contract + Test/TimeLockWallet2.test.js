const { expect } = require("chai");

describe("TimeLockWallet2", function () {
    let TimeLockWallet2, wallet;
    let owner, user;
    let unlockTime;

    beforeEach(async function () {
        [owner, user] = await ether.getSigners();

        unlockTime = (await ethers.provider.getBlock("latest")).timestamp + 60;

        TimeLockWallet2 = await ethers.getContractfactory("TimeLockWallet2");
        wallet = await TimeLockWallet2.deploy(unlockTime);
        await wallet.deployed();
    });

    it("Should initialize variables correctly", async function () {
        expect(await wallet.owner()).to.equal(owner.address);
        expect(await wallet.unlockTime()).to.equal(unlockTime);
    });

    it("Should allow user to deposit funds correctly", async function () {
        const amount = await ethers.utils.parseEther("1");

        await wallet.connect(user).deposit({ value: amount });

        const contractBalance = wallet.getBalance();
        expect(contractBalance).to.equal(amount);
    });

    it("Should approve withdrawals by the owner", async function () {
        await wallet.aproveWithdrawalsByOwner();

        const approvalStatus = await wallet.ownerApproval();
        expect(approvalStatus).to.be.true;
    });

    it("Should not allow withdrawal before unlockTime", async function () {
        await expect(wallet.connect(user).withdraw(ethers.utils.parseEther("1")))
            .to.be.revertedWith("You have to wait until funds are allowed to be unlocked");
    });

    it("Should allow withdrawal after unlock time", async function () {
        const depositAmount = ethers.utils.parseEther("1");
        await wallet.connect(user).deposit({ value: depositAmount });

        await ethers.provider.send("evm_increaseTime", [60]);
        await ethers.provider.send("evm_mine", []);

        await wallet.connect(owner).approveWithdrawalsByOwner();

        await wallet.approveWithdrawalsByOwner();

        await wallet.connect(user).withdraw(depositAmount);

        const contractBalance = wallet.getBalance();
        expect(contractBalance).to.equal(0);
    });

    it("Should not allow withdrawal if owner has not approved", async function () {
        const depositAmount = ether.utils.parseEther("1");
        await wallet.connect(user).deposit({ value: depositAmount });

        await ethers.provider.send("evm_increaseTime", [60]);
        await ethers.provider.send("evm_mine", [60]);

        await expect(wallet.connect(user).withdraw(depositAmount))
            .to.be.revertedWith("Owner has not approved withdrawals");
    });

    it("Should return the correct unlock time", async function () {
        const remainingTime = await wallet.getUnlockTime();
        expect(remainingTime).to.be.lessThanOrEqual(60);
    });
});