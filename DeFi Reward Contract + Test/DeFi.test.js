const { expect } = require("chai");

describe("SimpleDeFi", function () {
    let SimpleDeFi, defiContract;
    let token, owner, user1, user2;
    const interestRate = 5; //5% annual interest rate
    const rewardInterval = 365 * 24 * 60 * 60; //1 year in seconds

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        token = await ERC20Mock.deploy("DeFi Token", "DFT", owner.address, ethers.utils.parseEther("1000000"));
        await token.deployed();

        SimpleDeFi = await ethers.getContractFactory("SimpleDeFi");
        defiContract = await SimpleDeFi.deploy(token.address);
        await defiContract.deployed();

        await token.transfer(user1.address, ethers.utils.parseEther("1000"));
        await token.transfer(user2.address, ethers.utils.parseEther("1000"));

        await token.connect(user1).approve(defiContract.address, ethers.utils.parseEther("1000"));
        await token.connect(user2).approve(defiContract.address, ethers.utils.parseEther("1000"));
    });

    it("should allow a user to deposit tokens", async function () {
        await defiContract.connect(user1).deposit(ethers.utils.parseEther("100"));

        const userDeposit = await defiContract.deposits(user1.address);
        expect(userDeposit.amount).to.equal(ethers.utils.parseEther("100"));
        expect(userDeposit.rewards).to.equal(0);
    });

    it("should calculate rewards correctly over time", async function () {
        await defiContract.connect(user1).deposit(ethers.utils.parseEther("100"));

        await ethers.provider.send("evm_increaseTime", [rewardInterval]);
        await ethers.provider.send("evm_mine");

        const rewards = await defiContract.calculateRewards(user1.address);
        expect(rewards).to.be.closeTo(ethers.utils.parseEther("5"), ethers.utils.parseEther("0.01")); //5% of 100 tokens
    });

    it("should allow a user to withdraw tokens with rewards", async function () {
        await defiContract.connect(user1).deposit(ethers.utils.parseEther("100"));

        await ethers.provider.send("evm_increaseTime", [rewardInterval]);
        await ethers.provider.send("evm_mine");

        const userInitialBalance = await token.balanceOf(user1.address);

        await defiContract.connect(user1).withdraw(ethers.utils.parseEther("100"));

        const userFinalBalance = await token.balanceOf(user1.address);
        expect(userFinalBalance).to.be.closeTo(
            userInitialBalance.add(ethers.utils.parseEther("105")),
            ethers.utils.parseEther("0.01")
        );

        const userDeposit = await defiContract.deposits(user1.address);
        expect(userDeposit.amount).to.equal(0);
        expect(userDeposit.rewards).to.equal(0);
    });

    it("should not allow a user to withdraw more than their balance", async function () {
        await defiContract.connect(user1).deposit(ethers.utils.parseEther("100"));

        await expect(
            defiContract.connect(user1).withdraw(ethers.utils.parseEther("200"))
        ).to.be.revertedWith("Insufficient balance to withdraw");
    });

    it("should return the correct total balance of the contract", async function () {
        await defiContract.connect(user1).deposit(ethers.utils.parseEther("100"));
        await defiContract.connect(user2).deposit(ethers.utils.parseEther("200"));

        const totalBalance = await defiContract.totalBalance();
        expect(totalBalance).to.equal(ethers.utils.parseEther("300"));
    });

    it("should return the correct user deposit and rewards", async function () {
        await defiContract.connect(user1).deposit(ethers.utils.parseEther("100"));

        await ethers.provider.send("evm_increaseTime", [rewardInterval / 2]);
        await ethers.provider.send("evm_mine");

        const [amount, rewards] = await defiContract.getUserDeposit(user1.address);
        expect(amount).to.equal(ethers.utils.parseEther("100"));
        expect(rewards).to.be.closeTo(ethers.utils.parseEther("2.5"), ethers.utils.parseEther("0.01")); //2.5% of 100 tokens
    });
});
