const { expect } = require("chai");

describe("SimpleDAO", function () {
    let SimpleDAO, dao, owner, voter1, voter2;

    beforeEach(async function () {
        [owner, voter1, voter2] = await ethers.getSigners();
        SimpleDAO = await ethers.getContractFactory("DAO");
        dao = await SimpleDAO.deploy(2);
        await dao.deployed();
    });

    it("should create a proposal", async function () {
        await dao.connect(voter1).createProposal("Test Proposal");

        const proposal = await dao.proposals(1);
        expect(proposal.proposer).to.equal(voter1.address);
        expect(proposal.description).to.equal("Test Proposal");
        expect(proposal.status).to.equal(1);
    });

    it("should allow voting voting on a proposal", async function () {
        await dao.connect(voter1).createProposal("Test Proposal");

        await dao.connect(voter1).vote(1, 1);
        
    })
})