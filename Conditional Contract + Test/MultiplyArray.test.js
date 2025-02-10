const { expect } = require("chai");

describe("MultiplyArray", function () {
    let MultiplyArray, multiplyArray;
    let deployer;

    beforeEach(async function () {
        deployer = await ethers.getSigner();
        MultiplyArray = await ethers.getContractFactory("MultiplyArray");
        multiplyArray = await MultiplyArray.deploy();
        await multiplyArray.deployed();
    });

    it("should return the correct product of the numbers array", async function () {
        const result = await multiplyArray.multiplyNumber();
        expect(result).to.equal(24);
    });

    it("should store the correct initial array values", async function () {
        const num0 = await multiplyArrayContract.numbers(0);
        const num1 = await multiplyArrayContract.numbers(1);
        const num2 = await multiplyArrayContract.numbers(2);

        expect(num0.toNumber()).to.equal(2);
        expect(num1.toNumber()).to.equal(3);
        expect(num2.toNumber()).to.equal(4);
    });
});