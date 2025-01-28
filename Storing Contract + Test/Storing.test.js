const { expect } = require("chai");

describe("Storing", function () {
    let Storing, storing;

    beforeEach(async function () {
        Storing = await ethers.getContractFactory("Storing");
        storing = await Storing.deploy();
        await storing.deployed();
    });

    it("Should initialize the storedValue as zero", async function () {
        const storedValue = storing.get();
        expect(storedValue).to.equal(0);
    });

    it("Should set the storedValue", async function () {
        await storing.store(4);
        const storedValue = storing.get();
        expect(storedValue).to.equal(4);
    });

    it("Should get the storedValue", async function () {
        await storing.set(22);
        const storedValue = storing.get();
        expect(storedValue).to.equal(22);
    });
});