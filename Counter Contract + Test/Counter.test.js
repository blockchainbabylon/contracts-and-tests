const { expect } = require("chai")
const { ethers } = require("hardhat");

describe("Counter", function () {
    let Counter, counter;

    beforeEach(async function () {
        Counter = await ethers.getContractfactory("Counter");
        counter = await Counter.deploy();
        await counter.deployed();
    });

    it("Should return the inital count as zero", async function () {
        expect(await counter.getCount()).to.equal(0);
    });

    it("Should increment the count", async function () {
        await counter.increment();
        expect(await counter.getCount()).to.equal(1);
    });

    it("Should decrement the count", async function () {
        await counter.increment();
        await counter.decrement();
        expect(await counter.getCount()).to.equal(0);
    });

    it ("Should revert when trying to decrement below zero", async function () {
        await expect(counter.decrement()).to.be.revertedWith(
            "Counter: count cannot be less than zero"
        );
    });
});