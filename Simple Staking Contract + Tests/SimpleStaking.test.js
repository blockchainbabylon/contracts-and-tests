const { expect } = require("chai");

describe("SimpleStaking", function () {
    let SimpleStaking, stakingContract;
    let stakingToken, owner, user1, user2;
    const rewardRate = ethers.utils.parseEther("0.01");

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();

        const ERC20Mock = await ethers.getContractFactory("SimpleStaking");
        stakingToken = await ERC20Mock.deploy("Staking Token", "STK", owner.address, ethers.utils.parseEther("1000000"));
        await stakingToken.deployed();

        SimpleStaking = await ethers.getContractFactory("SimpleStaking");
        stakingContract = await SimpleStaking.deploy(stakingToken.address, rewardRate);
        await stakingContract.deployed();

        await stakingToken.transfer(user1.address, ethers.utils.parseEther("1000"));
        await stakingToken.transfer(user2.address, ethers.utils.parseEther("1000"));
    });

    it("should allow a user to stake tokens", async function () {
        await stakingToken.connect(user1).approve(stakingContract.address, ethers.utils.parseEther("100"));
        await stakingContract.connect(user1).stake(ethers.utils.parseEther("100"));

        const stakedBalance = await stakingContract.stakedBalance(user1.address);
        expect(stakedBalance).to.equal(ethers.utils.parseEther("100"));
    });
    
    it("should calculate rewards correctly over time", async function () {
        await stakingToken.connect(user1).approve(stakingContract.address, ethers.utils.parseEther("100"));
        await stakingContract.connect(user1).stake(ethers.utils.parseEther("100"));

        await ethers.provider.send("evm_increaseTime", [10]); //time increased by 10 seconds
        await ethers.provider.send("evm_mine");

        await stakingContract.connect(user1).claimRewards();

        const rewards = await stakingToken.balanceOf(user1.address);
        expect(rewards).to.be.closeTo(ethers.utils.parseEther("1"), ethers.utils.parseEther("0.01"));
    });

    it("should allow a user to withdraw staked tokens", async function () {
        await stakingToken.connect(user1).approve(stakingContract.address, ether.utils.parseEther("100"));
        await stakingContract.connect(user1).stake(ethers.utils.parseEther("100"));

        await stakingContract.connect(user1).withdraw(ethers.utils.parseEther("50"));

        const stakedBalance = await stakingContract.stakedBalance(user1.address);
        expect(stakedBalance).to.equal(ether.utils.parseEther("50"));

        const userBalance = await stakingToken.balanceOf(user1.address);
        expect(userBalance).to.equal(ethers.utils.parseEther("950")); //initial 1000 - 100 staked + 50 withdrawn
    });

    it("should not allow a user to withdraw more than their staked balance", async function () {
        await stakingToken.connect(user1).approve(stakingContract.address, ethers.utils.parseEther("100"));
        await stakingContract.connect(user1).stake(ethers.utils.parseEther("100"));

        await ethers.provider.send("evm_increaseTime", [10]);
        await ethers.provider.send("evm_mine");

        const initialBalance = await stakingToken.balanceOf(user1.address);

        await stakingContract.connect(user1).claimRewards();

        const finalBalance = await stakingToken.balanceOf(user1.address);
        expect(finalBalance).to.be.gt(initialBalance);
    });

    it("should not allow a user to claim rewards", async function () {
        await stakingToken.connect(user1).approve(stakingContract.address, ethers.utils.parseEther("100"));
        await stakingContract.connect(user1).stake(ethers.utils.parseEther("100"));

        await expect(stakingContract.connect(user1).claimRewards()).to.be.revertedWith("No rewars available");
    });
});
