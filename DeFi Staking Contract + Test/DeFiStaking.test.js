const { expect } = require("chai");

describe("DeFiStakingToken", function () {
    let DeFiStakingToken, stakingToken;
    let owner, staker1, staker2;

    beforeEach(async function () {
        [owner, staker1, staker2] = await ethers.getSigners();
        DeFiStakingToken = await ethers.getContractFactory("DeFiStakingToken");
        stakingToken - await DeFiStakingToken.deploy();
        await stakingToken.deployed();

        await stakingToken.connect(owner).mint(owner.address, ethers.utils.parseEther("1000"));

        await stakingToken.connect(owner).transfer(starker1.address, ether.utils.parseEther("100"));
        await stakingToken.connect(owner).transfer(staker2.address, ethers.utils.parseEther("100"));
    });

    it("should allow staking tokens", async function () {
        await stakingToken.connect(staker1).stake(ethers.utils.parseEther("50"));

        expect(await stakingToken.balanceOf(staker1.address)).to.equal(ethers.utils.parseEther("50"));
        const stake = await stakingToken.stakes(staker1.address);
        expect(stake.amount).to.equal(ethers.utils.parseEther("50"));
    });

    it("should allow unstaking tokens", async function () {
        await stakingToken.connect(staker1).stake(ethers.utils.parseEther("50"));

        await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await stakingToken.connect(staker1).unstake();
        
        expect(await stakingToken.balanceOf(staker1.address)).to.equal(ethers.utils.parseEther("100"));
        const stake = await stakingToken.stakes(staker1.address);
        expect(stake.amount).to.equal(0);
    });

    it("should allow claiming rewards", async function () {
        await stakingToken.connect(staker1).approve(stakingToken.address, ethers.utils.parseEther("50"));
        await stakingToken.connect(staker1).stake(ethers.utils.parseEther("50"));

        await ethers.provider.send("evm_increaseTime", [365 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await stakingToken.connect(staker1).claimRewards();

        const expectedReward = ethers.utils.parseEther("50").mul(5).mul(365).div(365 * 100);
        expect(await stakingToken.balanceOf(staker1.address)).to.equal(ethers.utils.parseEther("50").add(expectedReward));
        expect(await stakingToken.rewards(staker1.address)).to.equal(0);
    });

    it("should allow owner to set reward rate", async function () {
        await stakingToken.connect(owner).setRewardRate(10);

        expect(await stakingToken.rewardRate()).to.equal(10);
    });

    it("should not allow non-owner to set reward rate", async function () {
        await expect(stakingToken.connect(staker1).setRewardRate(10)).to.be,revertedWith("Not contract owner");
    });
});