const { expect } = require("chai");

describe("CandidateElection", function () {
    let CandidateElection, electionContract;
    let manager, voter1, voter2;

    beforeEach(async function () {
        [manager, voter1, voter2] = await ethers.getSigners();
        CandidateElection = await ethers.getContractFactory("Election");
        electionContract = await CandidateElection.deploy();
        await electionContract.deployed();
    });

    it("should allow adding a candidate", async function () {
        await electionContract.connect(manager).addCandidate("Richard");

        const candidate = await electionContract.candidates(1);
        expect(candidate.name).to.equal("Richard");
        expect(candidate.votes).to.equal(0);
    });

    it("should not allow adding a candidate after the election has ended", async function () {
        await electionContract.connect(owner).endElection();

        await expect(electionContract.connect(owner).addCandidate("Richard"))
        .to.be.revertedWith("Sorry, election ended");
    });

    it("should allow voting for a candidate", async function () {
        await electionContract.connect(owner).addCandidate("Richard");

        await electionContract.connect(voter1).vote(1);

        const candidate = await electionContract.candidates(1);
        expect(candidate.votes).to.equal(1);
        expect(await electionContract.hasVoted(voter1.address)).to.be.true;
    });

    it("should not allow voting twice", async function () {
        await electionContract.connect(owner).addCandidate("Richard");

        await electionContract.connect(voter1).vote(1);

        await expect(electionContract.connect(voter1).vote(1))
        .to.be.revertedWith("You have already voted");
    });

    it("should allow ending the election", async function () {
        await electionContract.connect(owner).addCandidate("Richard");
        await electionContract.connect(owner).addCandidate("Goodhue");

        await electionContract.connect(voter1).vote(1);
        await electionContract.connect(voter2).vote(2);

        await electionContract.connect(owner).endElection();

        expect(await electionContract.electionEnded()).to.be.true;
    });

    it("should not allow ending the election by non-manager", async function() {
        await electionContract.connect(owner).addCandidate("Richard");

        await expect(electionContract.connect(voter1).endElection())
        .to.be.revertedWith("Sorry, you are not the manager");
    });
});