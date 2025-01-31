const { expect } = require("chai");

describe("UserManagement", function () {
    let UserManagement, userManagement;
    let owner, addr1, addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        UserManagement = await ethers.getContractFactory("UserManagement");
        userManagement = await UserManagement.deploy();
        await userManagement.deployed();
    });

    it("Should initialize owner correctly", async function () {
        expect(await userManagement.owner()).to.equal(owner.address);
    });

    it("Should allow the owner to add a user", async function () {
        await userManagement.connect(owner).addUser(addr1.address, "Jit", 200);

        expect(await userManagement.userCount()).to.equal(1);

        const userInfo = userManagement.getUserInfo(addr1.address);
        expect(user[0]).to.equal("Jit");
        expect(user[1]).to.equal(200);
    });

    it("Should not allow anyone but owner to add a user", async function () {
        await expect(userManagement.connect(addr1)).addUser(addr2.address, "Bro", 600)
        .to.be.revertedWith("Sorry, you are not the owner");
    });

    it("Should allow the owner to update a user's balance", async function () {
        await userManagement.addUser(addr1.address, "Jit", 600);
        await userManagement.updateUserBalance(addr1.address, 6000);

        const user = await userManagement.getUserInfo(addr1.address);

        expect(user[1]).to.equal(6000);
    });

    it("Should not allow non-users to update a user's balance", async function () {
        await userManagement.addUser(addr2.address, "Jit", 600);

        await expect(userManagement.connect(addr1)).updateUserBalance(addr2.address, 6000)
        .to.be.revertedWith("Sorry, you are not the owner");
    });

    it("Should return the correct total user count", async function () {
        expect(await userManagement.getTotalUsers()).to.equal(0);

        await userManagement.addUser(addr1.address, "Bro", 56);
        await userManagement.addUser(addr2.address, "Jit", 600);

        expect(await userManagement.getTotalUsers()).to.equal(2);
    });
});