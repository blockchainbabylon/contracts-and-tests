const { expect } = require("chai");

describe("DynamicReputationToken", function () {
    let DynamicReputationToken, reputationToken;
    let RewardToken, rewardToken;
    let owner, user1, user2, user3;

    beforeEach(async function () {
        [owner, user1, user2, user3] = await ethers.getSigners();

        // Deploy a mock ERC20 token
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        rewardToken = await ERC20Mock.deploy("Reward Token", "RWT", ethers.utils.parseEther("1000000"));
        await rewardToken.deployed();

        // Deploy the DynamicReputationToken contract
        const DynamicReputationTokenFactory = await ethers.getContractFactory("DynamicReputationToken");
        reputationToken = await DynamicReputationTokenFactory.deploy(rewardToken.address);
        await reputationToken.deployed();

        // Fund the reputation token contract with reward tokens
        await rewardToken.transfer(reputationToken.address, ethers.utils.parseEther("100000"));
    });

    it("should allow the owner to award reputation", async function () {
        await reputationToken.connect(owner).awardReputation(user1.address, 100);

        const reputation = await reputationToken.reputationBalance(user1.address);
        expect(reputation).to.equal(100);

        const holders = await reputationToken.getReputationHolders();
        expect(holders.length).to.equal(1);
        expect(holders[0]).to.equal(user1.address);
    });

    it("should set the collective goal and calculate rewards per holder", async function () {
        await reputationToken.connect(owner).awardReputation(user1.address, 100);
        await reputationToken.connect(owner).awardReputation(user2.address, 200);

        await reputationToken.connect(owner).setCollectiveGoalMet(ethers.utils.parseEther("10000"));

        const rewardPerHolder = await reputationToken.rewardAmountPerHolder();
        expect(rewardPerHolder).to.equal(ethers.utils.parseEther("5000"));
    });

    it("should allow users to claim rewards after the goal is achieved", async function () {
        await reputationToken.connect(owner).awardReputation(user1.address, 100);
        await reputationToken.connect(owner).awardReputation(user2.address, 200);

        await reputationToken.connect(owner).setCollectiveGoalMet(ethers.utils.parseEther("10000"));

        await reputationToken.connect(user1).claimReward();

        const user1Balance = await rewardToken.balanceOf(user1.address);
        expect(user1Balance).to.equal(ethers.utils.parseEther("5000"));

        const reputation = await reputationToken.reputationBalance(user1.address);
        expect(reputation).to.equal(0);
    });

    it("should not allow users to claim rewards before the goal is achieved", async function () {
        await reputationToken.connect(owner).awardReputation(user1.address, 100);

        await expect(reputationToken.connect(user1).claimReward()).to.be.revertedWith("Collective goal not yet achieved");
    });

    it("should allow the owner to mark participation", async function () {
        await reputationToken.connect(owner).markParticipation(user1.address);

        const participated = await reputationToken.hasParticipatedInEvent(user1.address);
        expect(participated).to.be.true;
    });

    it("should allow users to access exclusive features if conditions are met", async function () {
        await reputationToken.connect(owner).awardReputation(user1.address, 100);
        await reputationToken.connect(owner).awardReputation(user2.address, 200);
        await reputationToken.connect(owner).awardReputation(user3.address, 300);

        await reputationToken.connect(owner).markParticipation(user1.address);
        await reputationToken.connect(owner).markParticipation(user2.address);
        await reputationToken.connect(owner).markParticipation(user3.address);

        const access = await reputationToken.hasAccessToExclusiveFeature(user1.address);
        expect(access).to.be.true;
    });

    it("should not allow users to access exclusive features if conditions are not met", async function () {
        await reputationToken.connect(owner).awardReputation(user1.address, 100);

        const access = await reputationToken.hasAccessToExclusiveFeature(user1.address);
        expect(access).to.be.false;
    });
});
