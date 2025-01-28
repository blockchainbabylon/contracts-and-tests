const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting", function () {
    let voting;
    let owner;
    let voter1;
    let voter2;

    beforeEach(async function () {
        [owner, voter1, voter2] = await ethers.getSigners();

        const Voting = await ethers.getContractFactory("Voting");
        voting = await ethers.deploy();
        await voting.deployed();
    });

    it("Should allow the owner to add candidates", async function () {
        await voting.addCandidate("Alice");
        await voting.addCandidate("Bob");

        const candidateCount = await voting.getCandidateCount();
        expect(candidateCount).to.equal(2);

        const [name1, votes1] = await voting.getCandidate(0);
        const [name2, votes2] = await voting.getCandidate(1);

        expect(name1).to.equal("Alice");
        expect(votes1).to.equal(0);
        expect(name2).to.equal("Bob");
        expect(votes2).to.equal(0);
    });

    it("Should emit an event when a candidate is added", async function () {
        await expect(voting.addCandidate("Charlie")).to.emit(voting, "CandidateAdded").withArgs("Charlie");
    });

    it("Should allow users to vote", async function () {
        await voting.addCandidate("Alice");
        await voting.connect(voter1).vote(0);

        const [name, votes] = await voting.getCandidate(0);
        expect(name).to.equal("Alice");
        expect(votes).to.equal(1);
    });

    it("Should not allow users to vote more than once", async function () {
        await voting.addCandidate("Alice");
        await voting.connect(voter1).vote(0);

        await expect(voting.connect(voter1).vote(0)).to.be.revertedWith("You have already voted");
    });

    it("Should emit an event when a user votes", async function () {
        await voting.addCandidate("Alice");

        await expect(voting.connect(voter1).vote(0))
        .to.emit(voting, "Voted")
        .withArgs(voter1.address, "Alice");
    });

    it("Should not allow voting for an invalid candidate index", async function () {
        await expect(voting.connect(voting1).vote(99)).to.be.revertedWith("Invalid candidate index");
    });
});