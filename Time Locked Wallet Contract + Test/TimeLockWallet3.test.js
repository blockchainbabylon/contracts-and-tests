const { expect } = require("chai");

describe("TimeLockedWallet", function () {
    let TimeLockedWallet, wallet;
    let owner, nonOwner;
    const unlockDuration = 60 * 60 * 24; //1 day

    beforeEach(async function () {
        [owner, nonOwner] = await ethers.getSigners();
        const currentTimestamp = (await ethers.provider.getBlock("latest")).timestamp;
        
        TimeLockedWallet = await ethers.getContractFactory("TimeLockedWallet");
        wallet = await TimeLockedWallet.deploy(unlockDuration);
        await wallet.deployed();
    });

    it("should initialize with the correct owner and unlock time", async function () {
        const currentTimestamp = (await ethers.provider.getBlock("latest")).timestamp;
        const unlockTime = await wallet.unlockTime();

        expect(await wallet.owner()).to.equal(owner.address);
        expect(unlockTime).to.be.closeTo(currentTimestamp + unlockDuration, 2); //allow small margin for blocktime
    });

    it("should allow deposits", async function () {
        await wallet.connect(owner).deposit({ value: ethers.utils.parseEther("1") });

        const walletBalance = await ethers.provider.getBalance(wallet.address);
        expect(walletBalance).to.equal(ethers.utils.parseEther("1"));
    });

    it("should not allow withdrawals before the unlock time", async function () {
        await wallet.connect(owner).deposit({ value: ethers.utils.parseEther("1") });
        
        await expect(wallet.connect(owner).withdrawal(ethers.utils.parseEther("1"))).to.be.revertedWith(
            "Sorry, your funds are still locked"
        );
    });

    it("should allow withdrawals after the unlock time", async function () {
        await wallet.connect(owner).deposit({ value: ethers.utils.parseEther("1") });

        await ethers.provider.send("evm_increaseTime", [unlockDuration + 1]);
        await ethers.provider.send("evm_mine");

        const ownerInitialBalance = await ethers.provider.getBalance(owner.address);

        const tx = await wallet.connect(owner).withdrawal(ethers.utils.parseEther("1"));
        const receipt = await tx.wait();
        const gasUsed = receipt.gasUsed.mul(receipt.effectiveGasPrice);

        const ownerFinalBalance = await ethers.provider.getBalance(owner.address);
        expect(ownerFinalBalance).to.be.closeTo(
            ownerInitialBalance.add(ethers.utils.parseEther("1")).sub(gasUsed),
            ethers.utils.parseEther("0.01")
        );
    });

    it("should not allow non-owners to withdraw funds", async function () {
        await wallet.connect(owner).deposit({ value: ethers.utils.parseEther("1") });

        await ethers.provider.send("evm_increaseTime", [unlockDuration + 1]);
        await ethers.provider.send("evm_mine");

        await expect(wallet.connect(nonOwner).withdrawal(ethers.utils.parseEther("1"))).to.be.revertedWith(
            "Sorry, you are not the owner"
        );
    });

    it("should return the correct time left until unlock", async function () {
        const timeLeftBefore = await wallet.getTimeLeft();
        expect(timeLeftBefore).to.be.closeTo(unlockDuration, 2);

        await ethers.prvider.send("evm_increaseTime", [unlockDuration / 2]);
        await ethers.provider.send("evm_mine");

        const timeLeftAfter = await wallet.getTimeLeft();
        expect(timeLeftAfter).to.be.closeTo(unlockDuration / 2, 2);
    });

    it("should return 0 time left after the unlock time has passed", async function () {
        await ethers.provider.send("evm_increaseTime", [unlockDuration + 1]);
        await ethers.provider.send("evm_mine");

        const timeLeft = await wallet.getTimeLeft();
        expect(timeLeft).to.equal(0);
    });
});
