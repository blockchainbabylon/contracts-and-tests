const { expect } = require("chai");

describe("KeccakPractice", function () {
    let KeccakPractice, keccakPractice;
    let owner, addr1;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        KeccakPractice = await ethers.getContractFactory("KeccakPractice");
        keccakPractice = await KeccakPractice.deploy();
        await keccakPractice.deployed();
    });

    it("Should store and verify data correctly", async function () {
        const data = "Hello World!";
        const timestamp = (await ethers.provider.getBlock("latest")).timestamp;

        await keccakPractice.connect(owner).storeData(data);

        const hash = ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(["string", "address", "uint256"], [data, owner.address, timestamp])
        );

        expect(await keccakPractice.verifyData(data, owner.address, timestamp)).to.equal(true);
    });

    it("Should not allow duplicate storage of the same data with the same sender and timestamp", async function () {
        const data = "Duplicate Test";

        await keccakPractice.connect(owner).storeData(data);

        await expect(keccakPractice.connect(owner).storeData(data))
        .to.be.revertedWith("Data already exists");
    });

    it("Should return false for non-existentent data", async function () {
        const data = "Non-existent Data";
        const timestamp = (await ethers.provider.getBlock("latest")).timestamp

        expect(await keccakPractice.verifyData(data, owner.address, timestamp)).to.equal(false);
    });

    it("Should allow multiple users to share similar data uniquely", async function () {
        const data = "Shared Data";

        await keccakPractice.connect(owner).storeData(data);
        await keccakPractice.connect(addr1).storeData(data);

        expect(await keccakPractice.verifyData(data, owner.address, (await ethers.provider.getBlock("latest")).timestamp)).to.equal(true);
        expect(await keccakPractice.verifyData(data, addr1.address, (await ethers.provider.getBlock("latest")).timestamp)).to.equal(true);
    });
});