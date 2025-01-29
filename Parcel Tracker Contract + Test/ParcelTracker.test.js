const { expect } = require("chai");

describe("ParcelTracker", function () {
    let ParcelTracker, parcelTracker;
    let owner, addr1, addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        ParcelTracker = await ethers.getContractFactory("ParcelTracker");
        parcelTracker = await ParcelTracker.deploy();
        await parcelTracker.deployed();
    });

    it("Should set the correct owner", async function () {
        expect(await parcelTracker.owner()).to.equal(owner.address);
    });

    it("Should initialize parcel count at zero", async function () {
        expect(await parcelTracker.parcelCount()).to.equal(0);
    });

    it("Should allow owner to add a parcel", async function () {
        const recipient = addr1.address;

        await expect(parcelTracker.connect(owner)).addParcel(addr1.address)
        .to.emit(parcelTracker, "ParcelAdded")
        .withArgs(1, addr1.address);

        const parcel = await parcelTracker.getStatus(1);
        expect(parcel.id).to.equal(1);
        expect(parcel.recipient).to.equal(addr1.address);
        expect(parcel.status).to.equal(0);
    });

    it("Should fail if non-owner tries to add a parcel", async function () {
        await expect(parcelTracker.connect(addr1)).addParcel(addr2.address)
        .to.be.revertedWith("You are not the owner");
    });

    it("Should allow owner to update the status", async function () {
        await parcelTracker.addParcel(addr1.address);

        await expect(parcelTracker.connect(owner)).updateStatus(1, 1)
        .to.emit(parcelTracker, "StatusUpdated")
        .withArgs(1, 1);

        const parcel = await parcelTracker.getStatus(1);
        expect(parcel.status).to.equal(1);
    });

    it("Should not allow updating to the same status", async function () {
        await parcelTracker.addParcel(addr1.address);

        await expect(parcelTracker.connect(owner)).updateStatus(1, 0)
        .to.be.revertedWith("Cannot update to same status");
    });

    it("Should fail if a non-owner tries to update the status", async function () {
        await parcelTracker.addParcel(addr1.address);
        
        await expect(parcelTracker.connect(addr1)).updateStatus(1, 3)
        .to.be.revertedWith("You are not the owner");
    });
});