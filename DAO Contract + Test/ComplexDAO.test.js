const { expect } = require("chai");

describe("DeFiDAO", function () {
    let DeFiDAO, dao;
    let admin, user1, user2;
    const initialMint = ethers.utils.parseEther("1000000");

    beforeEach(async function () {
        [admin, user1, user2] = await ethers.getSigners();
        DeFiDAO = await ethers.getContractFactory("DeFiDAO");
        dao = await DeFiDAO.deploy();
        await dao.deployed();
    });

    it("should mint tokens to the admin", async function () {
        expect(await dao.balances(admin.address)).to.equal(initialMint);
    });

    it("should transfer tokens", async function () {
        await dao.connect(admin).transfer(user1.address, ethers.utils.parseEther("1000"));

        expect(await dao.balances(admin.address)).to.equal(initialMint.sub(ethers.utils.parseEther("1000")));
        expect(await dao.balances(user1.address)).to.equal(ethers.utils.parseEther("1000"));
    });

    it("should stake tokens", async function () {
        await dao.connect(admin).transfer(user1.address, ethers.utils.parseEther("1000"));

        await dao.connect(user1).stake(ethers.utils.parseEther("500"));

        expect(await dao.balances(user1.address)).to.equal(ethers.utils.parseEther("500"));
        expect(await dao.stakedBalance(user1.address)).to.equal(ethers.utils.parseEther("500"));
    });

    it("should unstake tokens with rewards", async function () {
        await dao.connect(admin).transfer(user1.address, ethers.utils.parseEther("1000"));

        await dao.connect(user1).stake(ethers.utils.parseEther("500"));

        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await dao.connect(user1).unstake(ethers.utils.parseEther("500"));

        const reward = ethers.utils.parseEther("25");
        const treasuryCut = reward.div(5);
        const userReward = reward.sub(treasuryCut);

        expect(await dao.balances(user1.address)).to.equal(ethers.utils.parseEther("500").add(userReward));
        expect(await dao.stakedBalance(user1.address)).to.equal(0);
        expect(await dao.treasuryBalance()).to.equal(treasuryCut);
    });

    it("should create a proposal", async function () {
        await dao.connect(admin).transfer(user1.address, ethers.utils.parseEther("1000"));

        await dao.connect(user1).stake(ethers.utils.parseEther("500"));

        const tx = await dao.connect(user1).createProposal("Increase reward rate", 10);
        const receipt = await tx.wait();
        const proposalId = receipt.events[0].args.proposalId

        const proposal = await dao.proposals(porposalId);
        expect(proposal.proposer).to.equal(user1.address);
        expect(proposal.description).to.equal("Increase reward rate");
        expect(proposal.newRewardRate).to.equal(10);
    });

    it("should vote on a proposal", async function () {
        await dao.connect(admin).transfer(user1.address, ethers.utils.parseEther("1000"));
        await dao.connect(admin).transfer(user2.address, ethers.utils.parseEther("1000"));

        await dao.connect(user1).stake(ethers.utils.parseEther("500"));
        await dao.connect(user2).stake(ethers.utils.parseEther("500"));

        const tx = await dao.connect(user1).createProposal("Increase reward rate", 10);
        const receipt = await tx.wait();
        const proposalId = receipt.events[0].args.proposalId;

        await dao.connect(user1).vote(proposalId, true);
        await dao,connect(user2).vote(proposalId, false);

        const proposal = await dao.proposals(proposalId);
        expect(proposal.votesFor).to.equal(ethers.utils.parseEther("500"));
        expect(proposal.votesAgainst).to.equal(ethers.utils.parseEther("500"));
    });

    it("should execute a proposal", async function () {
        await dao.connect(admin).transfer(user1.address, ethers.utils.parseEther("1000"));
        await dao.connect(admin).transfer(user2.adress, ethers.utils.parseEther("1000"));

        await dao.connect(user1).stake(ethers.utils.parseEther("500"));
        await dao.connect(user2).stake(ethers.utils.parseEther("500"));

        const tx = await dao.connect(user1).createProposal("Increase reward rate", 10);
        const receipt = await tx.wait();
        const proposalId = receipt.events[0].args.proposalId;

        await dao.connect(user1).vote(proposalId, true);
        await dao.connect(user2).vote(proposalId, false);

        await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);
        await ethers.provider.sender("evm_mine");

        await dao.connect(user1).executeProposal(proposalId);

        const proposal = await dao.proposals(proposalId);
        expect(proposal.executed).to.be.true;
        expect(await dao.rewardRate()).to.equal(10);
    });

    it("should withdraw from the treasury", async function () {
        await dao.connect(admin).transfer(user1.address, ethers.utils.parseEther("1000"));

        await dao.connect(user1).stake(ethers.utils.parseEther("500"));

        await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await dao.connect(admin).withdrawTreasury(treasuryBalance, admin.address);

        expect(await dao.treasuryBalance()).to.equal(0);
    });
});
