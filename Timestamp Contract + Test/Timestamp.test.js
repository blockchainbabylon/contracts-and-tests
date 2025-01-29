const { expect } = require("chai");

describe("TimestampTracker", function () {
    let TimestampTracker, tracker;
    let owner, addr1;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        TimestampTracker = await ethers.getContractFactory();
        tracker = await TimestampTracker.deploy();
        await tracker.deployed();
    });

    it("Should create an entry with the current block timestamp", async function () {
        const currentTime = (await ethers.provider.getBlock("latest")).timestamp;

        const data = "First entry";
        await expect(tracker.connect(owner).createEntry(data))
            .to.emit(tracker, "EntryCreated")
            .withArgs(owner.address, data, currentTime);

        const entry = await tracker.entries(owner.address);
        expect(entry.data).to.equal(data);
        expect(entry.timestamp).to.be.closeTo(currentTime, 2);
    });

    it("Should calculate the correct entry age", async function () {
        const data = "Entry for addr1";
        await tracker.connect(addr1).createEntry(data);

        await ethers.provider.send("evm_increaseTime", [10]);
        await ethers.provider.send("evm_mine");

        const age = await tracker.getEntryAge(addr1.address);
        expect(age).to.be.closeTo(10, 1);
    });

    it("Should prevent creating multiple entries for the same user", async function () {
        await tracker.connect(owner).createEntry("First Entry");
        await expect(tracker.connect(owner).createEntry("Second entry")).to.be.revertedWith(
            "Entry already exists"
        );
    });

    it("Should prevent creating an entry with empty data", async function () {
        await expect(tracker.connect(owner).createEntry("")).to.be.revertedWith(
            "Data cannot be empty"
        );
    });

    it("Should prevent getting the age of a non-existent entry", async function () {
        await expect(tracker.getEntryAge(addr1.address)).to.be.revertedWith(
            "No entry for this user"
        );
    });
});