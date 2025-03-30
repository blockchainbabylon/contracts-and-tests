const { expect } = require("chai");

describe("VestingVault", function () {
    let VestingVault, vestingVault;
    let token, owner, beneficiary;
    const vestingDuration = 365 * 24 * 60 * 60; // 1 year in seconds
    const cliffDuration = 30 * 24 * 60 * 60; // 30 days in seconds

    beforeEach(async function () {
        [owner, beneficiary] = await ethers.getSigners();

        // Deploy a mock ERC20 token
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        token = await ERC20Mock.deploy("Test Token", "TT", owner.address, ethers.utils.parseEther("1000000"));
        await token.deployed();

        // Deploy the VestingVault contract
        const VestingVaultFactory = await ethers.getContractFactory("VestingVault");
        vestingVault = await VestingVaultFactory.deploy(
            token.address,
            beneficiary.address,
            vestingDuration,
            cliffDuration
        );
        await vestingVault.deployed();

        // Approve the VestingVault contract to transfer tokens on behalf of the owner
        await token.connect(owner).approve(vestingVault.address, ethers.utils.parseEther("1000000"));
    });

    it("should initialize with correct parameters", async function () {
        expect(await vestingVault.token()).to.equal(token.address);
        expect(await vestingVault.beneficiary()).to.equal(beneficiary.address);
        expect(await vestingVault.vestingDuration()).to.equal(vestingDuration);
        expect(await vestingVault.cliffDuration()).to.equal(cliffDuration);
    });

    it("should allow the owner to deposit tokens", async function () {
        const depositAmount = ethers.utils.parseEther("100000");

        await vestingVault.connect(owner).deposit(depositAmount);

        expect(await vestingVault.totalDeposited()).to.equal(depositAmount);
        expect(await token.balanceOf(vestingVault.address)).to.equal(depositAmount);
    });

    it("should not allow deposits after revocation", async function () {
        const depositAmount = ethers.utils.parseEther("100000");

        await vestingVault.connect(owner).deposit(depositAmount);
        await vestingVault.connect(owner).revoke();

        await expect(vestingVault.connect(owner).deposit(depositAmount)).to.be.revertedWith("Vesting revoked");
    });

    it("should allow the beneficiary to claim tokens after the cliff", async function () {
        const depositAmount = ethers.utils.parseEther("100000");

        await vestingVault.connect(owner).deposit(depositAmount);

        // Fast forward time to after the cliff duration
        await ethers.provider.send("evm_increaseTime", [cliffDuration]);
        await ethers.provider.send("evm_mine");

        const claimable = await vestingVault.claimableAmount();
        expect(claimable).to.be.gt(0);

        await vestingVault.connect(beneficiary).claim();

        expect(await vestingVault.totalClaimed()).to.equal(claimable);
        expect(await token.balanceOf(beneficiary.address)).to.equal(claimable);
    });

    it("should not allow the beneficiary to claim tokens before the cliff", async function () {
        const depositAmount = ethers.utils.parseEther("100000");

        await vestingVault.connect(owner).deposit(depositAmount);

        await expect(vestingVault.connect(beneficiary).claim()).to.be.revertedWith("Cliff not reached");
    });

    it("should allow the owner to revoke the vesting", async function () {
        const depositAmount = ethers.utils.parseEther("100000");

        await vestingVault.connect(owner).deposit(depositAmount);

        // Fast forward time to halfway through the vesting duration
        await ethers.provider.send("evm_increaseTime", [vestingDuration / 2]);
        await ethers.provider.send("evm_mine");

        const vested = await vestingVault.claimableAmount();
        const unvested = depositAmount.sub(vested);

        await vestingVault.connect(owner).revoke();

        expect(await token.balanceOf(owner.address)).to.equal(unvested);
        expect(await vestingVault.claimableAmount()).to.equal(0);
    });

    it("should not allow the owner to revoke twice", async function () {
        const depositAmount = ethers.utils.parseEther("100000");

        await vestingVault.connect(owner).deposit(depositAmount);
        await vestingVault.connect(owner).revoke();

        await expect(vestingVault.connect(owner).revoke()).to.be.revertedWith("Already revoked");
    });

    it("should calculate claimable tokens correctly", async function () {
        const depositAmount = ethers.utils.parseEther("100000");

        await vestingVault.connect(owner).deposit(depositAmount);

        // Fast forward time to halfway through the vesting duration
        await ethers.provider.send("evm_increaseTime", [vestingDuration / 2]);
        await ethers.provider.send("evm_mine");

        const claimable = await vestingVault.claimableAmount();
        expect(claimable).to.be.closeTo(depositAmount.div(2), ethers.utils.parseEther("0.01"));
    });
});
