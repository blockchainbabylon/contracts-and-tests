const { expect } = require("chai");

describe("Lottery", function () {
    let Lottery, lottery;
    let manager, participant1, participant2, participant3;
    const entryFee = ethers.utils.parseEther("0.1");

    befireEach(async function () {
        [manager, participant1, participant2, participant3] = await ethers.getSigners();
        Lottery = await ethers.getContractFactory("Lottery");
        lottery = await Lottery.deploy(entryFee);
        await lottery.deployed();
    });

    it("should initialize the contract with the correct manager and entry fee", async function () {
        expect(await lottery.manager()).to.equal(manager.address);
        expect(await lottery.entryFee()).to.equal(entryFee);
        expect(await lottery.lotteryActive()).to.be.false;
    });

    it("should allow the manager to start the lottery", async function () {
        await lottery.connect(manager).startLottery();

        const [lotteryActive, participantsCount] = lottery.getLotteryStatus();
        expect(lotteryActive).to.be.true;
        expect(participantsCount).to.equal(0);
    });

    it("should not allow non-managers to start the lottery", async function () {
        await expect(lottery.connect(participant1).startLottery()).to.be.revertedWith("Only the manager can perform this action");
    });

    it("should allow participants to enter the lottery", async function () {
        await lottery.connect(manager).startLottery();

        await lottery.connect(participant1).enterLottery({ value: entryFee });
        await lottery.connect(participant2).enterLottery({ value: entryFee });

        const participants = await lottery.getParticipants();
        expect(participants).to.include(participant1.address);
        expect(participants).to.include(participant2.address);

        const [lotteryActive, participantsCount] = await lottery.getLotteryStatus();
        expect(lotteryActive).to.be.true;
        expect(participantsCount).to.equal(2);
    });

    it("should not allow participants to enter with incorrect entry fee", async function () {
        await lottery.connect(manager).startLottery();

        await expect(lottery.connect(participant1).enterLottery({ value: ethers.utils.parseEther("0.05") })).to.be.revertedWith("Incorrect entry fee");
    });

    it("should allow the manager to end the lottery and transfer funds to the winner", async function () {
        await lottery.connect(manager).startLottery();

        await lottery.connect(participant1).enterLottery({ value: entryFee });
        await lottery.connect(participant2).enterLottery({ value: entryFee });
        await lottery.connect(participant3).enterLottery({ value: entryFee });

        const participants = await lottery.getParticipants();

        //gets all addresses eth balance before end of lottery
        const initialBalances = await Promise.all(participants.map(async (participant) => {
            return await ethers.provider.getBalance(participant);
        }));

        const tx = await lottery.connect(manager).endLottery();
        const receipt = await tx.wait();

        const winnerAddress = receipt.events.find((event) => event.event === "LotteryEnded").args.winner;

        const winnerIndex = participants.indexOf(winnerAddress);
        const winnerBalance = await ethers.provider.getBalance(winnerIndex);

        const totalPrize = entryFee.mul(participants.length);
        expect(winnerBalance).to.be.closeTo(initialBalances[winnerIndex].add(totalPrize), ethers.utils.parseEther("0.01"));

        const [lotteryActive, participantsCount] = await lottery.getLotteryStatus();
        expect(lotteryActive).to.be.false;
        expect(participantsCount).to.equal(0);
    });

    it("should not allow the manager to end the lottery if there are no participants", async function () {
        await lottery.connect(manager).startLottery();
        await expect(lottery.connect(manager).endLottery()).to.be.revertedWith("No participants in the lottery");
    });

    it("should not allow non-managers to end the lottery", async function () {
        await lottery.connect(manager).startLottery();

        await lottery.connect(participant1).enterLottery({ value: entryFee });

        await expect(lottery.connect(participant1).endLottery()).to.be.revertedWith("Only the manager can perform this action");
    });
});
