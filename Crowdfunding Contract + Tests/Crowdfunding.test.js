const { expect } = require("chai");

describe("Crowdfunding Contract", function () {
    let Crowdfunding, crowdfunding;
    let owner, addr1, addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        Crowdfunding = await ethers.getContractFctory("Crowdfunding");
        crowdfunding = await Crowdfunding.deploy();
        await crowdfunding.deployed();
    });

    it("should create a project correctly", async function () {
        const tx = await crowdfunding.createProject(ethers.utils.parseEther("1"), 7);
        const receipt = await tx.wait();

        const projectId = receipt.events[0].arg.projectId;
        const project = await crowdfunding.getProjectDetails(projectId);

        expect(project.creator).to.equal(owner.address);
        expect(project.goal).to.equal(ethers.utils.parseEther("1"));
        expect(project.finalized).to.equal(false);
    });

    it("should accept contributions", async function () {
        const tx = await crowdfunding.createProject(ethers.utils.parseEther("1"), 7);
        const receipt = await tx.wait();
        const projectId = receipt.events[0].args.projectId;

        await crowdfunding.connect(addr1).contribute(projectId, { value: ethers.utils.parseEther("0.5") });

        const contribution = await crowdfunding.getContribution(projectId, addr1.address);
        expect(contribution).to.equal(ethers.utils.parseEther("0.5"));

        const project = await crowdfunding.getProjectDetails(projectId);
        expect(project.raisedAmount).to.equal(ethers.utils.parseEther("0.5"));
    });

    it("should finalize project and transfer funds if goal is met", async function () {
        const tx = await crowdfunding.createProject(ethers.utils.parseEther("1"), 0);
        const receipt = await tx.wait();
        const projectId = receipt.events[0].args.projectId;

        await crowdfunding.connect(addr1).contribute(projectId, { value: ethers.utils.parseEther("1") });

        await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        const initialBalance = await ethers.provider.getBalance(owner.address); //balance before finalizing
        const finalizeTx = await crowdfunding.finalizeProject(projectId);
        await finalizeTx.wait();

        const project = await crowdfunding.getProjectDetials(projectId);
        expect(project.finalized).to.be.true; 

        const finalBalance = await ethers.provider.getBalance(owner.address);
        expect(finalBalance).to.be.above(intialBalance); //+1 ether in owner balance
    });

    it("should allow refunds if project fails", async function () {
        const tx = await crowdfunding.createProject(ethers.utils.parseEther("10"), 0);
        const receipt = await tx.wait();
        const projectId = receipt.events[0].args.projectId;

        await crowdfunding.connect(addr1).contribute(projectId, { value: ethers.utils.parseEther("1") });

        await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await crowdfunding.finalizeProject(projectId);

        const initialBalance = await ethers.provider.getBalance(addr1.address);

        const refundTx = await crowdfunding.connect(addr1).requestRefund(projectId);
        const refundReceipt = await refundTx.wait();
        const gasUsed = refundReceipt.gasUsed.mul(refundReceipt.effectiveGasPrice);

        const finalBalance = await ethers.provider.getBalance(addr1.address);
        expect(finalBalance.add(gasUsed)).to.be.closeTo(
            initialBalance.add(ethers.utils.parseEther("1")),
            ethers.utils.parseEther("0.01") //slippage tolerance
        );
    });

    it("should not allow contribute after deadline", async function () {
        const tx = await crowdfunding.createProject(ethers.utils.parseEther("1"), 0);
        const receipt = await tx.wait();
        const projectId = receipt.events[0].args.projectId;

        await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]);
        await ethers.provider.send("evm_mine");

        await expect(
            crowdfunding.connect(addr1).contribute(projectId, { value: ethers.utils.parseEther("0.05") })
        ).to.be.revertedWith("Project deadline has passed");
    });
});
