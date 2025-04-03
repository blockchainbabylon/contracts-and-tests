const { expect } = require("chai");

describe("VotingContract", function () {
    let VotingContract, votingContract;
    let owner, voter1, voter2, voter3;

    beforeEach(async function () {
        [owner, voter1, voter2, voter3] = await ethers.getSigners();

        VotingContract = await ethers.getContractFactory("VotingContract");
        votingContract = await VotingContract.deploy();
        await votingContract.deploy();
    });

    it("should initialize with the correct owner and voting closed", async function () {
        expect(await votingContract.owner()).to.equal(owner.address);
        expect(await votingContract.votingOpen()).to.be.false;
    });

    it("should allow the owner to open and close voting", async function () {
        await votingContract.connect(owner).openVoting();
        expect(await votingContract.votingOpen()).to.be.true;

        await votingContract.connect(owner).closeVoting();
        expect(await votingContract.votingOpen()).to.be.false;
    });

    it("should not allow non-owners to open or close voting", async function () {
        await expect(votingContract.connect(voter1).openVoting()).to.be.revertedWith("You are not the owner");
        await expect(votingContract.connect(voter1).closeVoting()).to.be.revertedWith("You are not the owner");
    });

    it("should allow users to register as voters", async function () {
        await votingContract.connect(voter1).registerVoter();
        const voter = await votingContract.voters(voter1.address);
        expect(voter.voterAddress).to.equal(voter1.address);
        expect(voter.voteStatus).to.equal(0); // NotVoted
    });

    it("should not allow users to register more than once", async function () {
        await votingContract.connect(voter1).registerVoter();
        await expect(votingContract.connect(voter1).registerVoter()).to.be.revertedWith("Already registered");
    });

    it("should allow registered voters to vote when voting is open", async function () {
        await votingContract.connect(owner).openVoting();
        await votingContract.connect(voter1).registerVote();
        await votingContract.connect(voter1).vote(1); //Vote for CandidateA

        const voter = await votingContract.voters(voter1.address);
        expect(voter.voteStatus).to.equal(1);

        const [votesA, votesB] = await votingContract.getTotalVotes();
        expect(votesA).to.equal(1);
        expect(votesB).to.equal(0);
    });

    it("should not allow unregistered users to vote", async function () {
        await votingContract.connect(owner).openVoting();
        await expect(votingContract.connect(voter1).vote(1)).to.be.revertedWith("You are not registered");
    });

    it("should not allow voters to vote more than once", async function () {
        await votingContract.connect(owner).openVoting();
        await votingContract.connect(voter1).registerVoter();
        await votingContract.connect(voter1).vote(1);

        await expect(votingContract.connect(voter1).vote(1)).to.be.revertedWith("You have already voted");
    });

    it("should not allow voting when voting is closed", async function () {
        await votingContract.connect(voter1).registerVoter();
        await expect(votingContract.connect(voter1).vote(1)).to.be.revertedWith("Voting is not open");
    });

    it("should return the correct total votes", async function () {
        await votingContract.connect(owner).openVoting();
        await votingContract.connect(voter1).registerVoter();
        await votingContract.connect(voter2).registerVoter();
        await votingContract.connect(voter1).vote(1);
        await votingContract.connect(voter2).vote(2);

        const [votesA, votesB] = await votingContract.getTotalVotes();
        expect(votesA).to.equal(1);
        expect(votesB).to.equal(1);
    });

    it("should return the correct voting status for a voter", async function () {
        await votingContract.connect(owner).openVoting();
        await votingContract.connect(voter1).registerVoter();
        await votingContract.connect(voter1).vote(1);

        const voteStatus = await votingContract.connect(voter1).getVotingStatus();
        expect(voteStatus).to.equal(1);
    });
});
