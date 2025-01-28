const { expect } = require("chai");

describe("Conditional", function () {
    let conditional;

    beforeEach(async function () {
        const Conditional = await ethers.getContractFactory("Conditional");
        conditional = await Conditional.deploy();
        await conditional.deployed();
    });

    it("Should return false when storedValue equals input value", async function {
        const result = conditional.ifelse(8);
        expect(result).to.equal(false);
    });

    it("Should also return false if value is seven", async function () {
        const result = conditional.ifelse(7);
        expect(result).to.equal(false);
    });

    it("Should return true if value is not 7 or 8", async function {
        const result = conditional.ifelse(6);
        expect(result).to.equal(true);
    });
});