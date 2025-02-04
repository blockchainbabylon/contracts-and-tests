const { expect } = require("chai");

describe("Voting2", function () {
    let Voting2, voting;
    let addr1, addr2;

    beforeEach(async function () {
        [addr1, addr2] = await ethers.getSigners();
        Voting2 = await ethers.getContractFactory("Voting2");
        voting = await Voting2.deploy();
        await voting.deployed();
    });

    it("Should allow a user to vote", async function () {
        await expect(voting.vote(true))
            .to.emit(voting, "Voted")
            .withArgs(addr1.address, 1 (await ethers.provider.getBlock("latest")).timestamp);
        
        const voter = await voting.voters(addr1.address);
        expect(voter.hasVoted).to.be.true;
        expect(voter.vote).to.equal(1);

        const result = await voting.getVotingResult();
        expect(result[0]).to.equal(1);
        expect(result[1]).to.equal(0);
    });

    it("Should not allow a user to vote twice", async function () {
        await voting.connect(addr1).vote(true);

        await expect(voting.vote(false))
            .to.be.revertedWith("You have already voted");
    });

    it("Should return the correct vote details", async function () {
        await voting.vote(true);

        const details = await voting.getVoteDetails(addr1.address);
        expect(details[0]).to.equal(1);
        expect(details[1]).to.be.a("number");
    });

    it("Should return correct voting result", async function () {
        await voting.vote(true);
        await voting.connect(addr2).vote(false);

        const result = await voting.getVotingResult();
        expect(result[0]).to.equal(1);
        expect(result[1]).to.equal(1);
    });
});