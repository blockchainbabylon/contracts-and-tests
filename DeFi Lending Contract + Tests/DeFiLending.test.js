const { expect } = require("chai");

describe("Lending", function () {
    let Lending, lending;
    let owner, user1, user2;
    const INTEREST_RATE = 5;
    const COLLATERAL_RATIO = 150;
    const LIQUIDATION_THRESHOLD = 120;

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        Lending = await ethers.getContractFactory("Lending");
        lending = await Lending.deploy();
        await lending.deployed();
    });

    it("should allow a user to deposit Ether", async function () {
        await lending.connect(user1).deposit({ value: ethers.utils.parseEther("1") });

        const user = await lending.users(user1.address);
        expect(user.deposit).to.equal(ethers.utils.parseEther("1"));
    });

    it("should allow a user to borrow Ether against their collateral", async function () {
        await lending.connect(user1).deposit({ value: ethers.utils.parseEther("1") });

        const maxBorrow = ethers.utils.parseEther("1").mul(100).div(COLLATERAL_RATIO);
        await lending.connect(user1).borrow(maxBorrow);

        const user = await lending.users(user1.address);
        expect(user.borrowed).to.equal(maxBorrow);
    });

    it("should not allow borrowing more than the collateral allows", async function () {
        await lending.connect(user1).deposit({ value: ethers.utils.parseEther("1") });
        
        const overBorrow = ethers.utils.parseEther("1").mul(100).div(COLLATERAL_RATIO).add(ethers.utils.parseEther("0.01"));
        await expect(lending.connect(user1).borrow(overBorrow)).to.be.revertedWith("Insufficient collateral");
    });

    it("should allow a user to repay their borrowed amount", async function () {
        await lending.connect(user1).deposit({ value: ethers.utils.parseEther("1") });

        const borrowAgainst = ether.utils.parseEther("0.5");
        await lending.connect(user1).borrow(borrowAmount);

        await lending.connect(user1).repay({ value: borrowAmount });

        const user = await lending.users(user1.address);
        expect(user.borrowed).to.equal(0);
    });

    it("should not allow overpayment when repaying", async function () {
        await lending.connect(user1).deposit({ value: ethers.utils.parseEther("1") });

        const borrowAmount = ethers.utils.parseEther("0.5");
        await lending.connect(user1).borrow(borrowAmount);

        const overPay = ethers.utils.parseEther("0.6");
        await expect(lending.connect(user1).repay({ value: overPay })).to.be.revertedWith("Overpayment not allowed");
    });

    it("should allow liquidation if collateral falls below the liquidation threshold", async function () {
        await lending.connect(user1).deposit({ value: ethers.utils.parseEther("1") });
    
        const borrowAmount = ethers.utils.parseEther("0.9");
        await lending.connect(user1).borrow(borrowAmount);
    
        await ethers.provider.send("evm_increaseTime", [365 * 24 * 60 * 60]); // 1 year
        await ethers.provider.send("evm_mine");
    
        const liquidatorInitialBalance = await ethers.provider.getBalance(user2.address);
    
        await lending.connect(user2).liquidate(user1.address);
    
        const liquidatorFinalBalance = await ethers.provider.getBalance(user2.address);
        expect(liquidatorFinalBalance).to.be.closeTo(
            liquidatorInitialBalance.add(ethers.utils.parseEther("1")),
            ethers.utils.parseEther("0.01") // Accounting for gas fees
        );
    
        const user = await lending.users(user1.address);
        expect(user.deposit).to.equal(0);
        expect(user.borrowed).to.equal(0);
    });
    
    it("should not allow liquidation if collateral is above the liquidation threshold", async function () {
        await lending.connect(user1).deposit({ value: ethers.utils.parseEther("1") });

        const borrowAmount = ethers.utils.parseEther("0.5");
        await lending.connect(user1).borrow(borrowAmount);

        await expect(lending.connect(user2).liquidation(user1.address)).to.be.revertedWith("Cannot liquidate");
    });
});
