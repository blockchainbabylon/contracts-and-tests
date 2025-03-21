const { expect } = require("chai");

describe("MultiSigWallet", function () {
    let MultiSigWallet, wallet;
    let owner1, owner2, owner3, nonOwner, recipient;
    const quorum = 2;

    beforeEach(async function () {
        [owner1, owner2, owner3, nonOwner, recipient] = await ethers.getSigners();
        MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
        wallet = await MultiSigWallet.deploy([owner1.address, owner2.address, owner3.address], quorum);
        await wallet.deployed();

        await owner1.sendTransaction({
            to: wallet.address,
            value: ethers.utils.parseEther("10"),
        });
    });

    it("should initialize with correct owners and quorum", async function () {
        expect(await wallet.getOwnersCount()).to.equal(3);
        expect(await wallet.quorum()).to.equal(quorum);
        expect(await wallet.getOwner(0)).to.equal(owner1.address);
        expect(await wallet.getOwner(1)).to.equal(owner2.address);
        expect(await wallet.getOwner(2)).to.equal(owner3.address);
    });

    it("should allow an owner to propose a transaction", async function () {
        const tx = await wallet.connect(owner1).proposeTransaction(
            recipient.address,
            ethers.utils.parseEther("1"),
            "Payment for services"
        );
        const receipt = await tx.wait();
        const transactionId = receipt.events[0].args.transactionId;

        const transaction = await wallet.getTransaction(transactionId);
        expect(transaction.to).to.equal(recipient.address);
        expect(transaction.amount).to.equal(ethers.utils.parseEther("1"));
        expect(transaction.description).to.equal("Payment for services");
        expect(transaction.executed).to.be.false;
        expect(transaction.approvalCount).to.equal(0);
    });

    it("should allow owner to approve a transaction", async function () {
        await wallet.connect(owner1).proposeTransaction(
            recipient.address,
            ethers.utils.parseEther("1"),
            "Payment for services"
        );

        await wallet.connect(owner1).approveTransaction(0);
        await wallet.connect(owner2).approveTransaction(0);

        const transaction = await wallet.getTransaction(0);
        expect(transaction.approvalCount).to.equal(2);
    });

    it("should execute a transaction once quorum is reached", async function () {
        const recipientInitialBalance = await ethers.provider.getBalance(recipient.address);

        await wallet.connect(owner1).proposeTransaction(
            recipient.address,
            ethers.utils.parseEther("1"),
            "Payment for services"
        );

        await wallet.connect(owner1).approveTransaction(0);
        await wallet.connect(owner2).approveTransaction(0);

        const transaction = await wallet.getTransaction(0);
        expect(transaction.executed).to.be.true;

        const recipientFinalBalance = await ethers.provider.getBalance(recipient.address);
        expect(recipientFinalBalance).to.equal(recipientInitialBalance.add(ethers.utils.parseEther("1")));
    });

    it("should not allow non-owners to propose transactions", async function () {
        await expect(
            wallet.connect(nonOwner).proposeTransaction(
                recipient.address,
                ethers.utils.parseEther("1"),
                "Payment for services"
            )
        ).to.be.revertedWith("You are not the owner");
    });

    it("should not allow non-owners to approve transactions", async function () {
        await wallet.connect(owner1).proposeTransaction(
            recipient.address,
            ethers.utils.parseEther("1"),
            "Payment for services"
        );

        await expect(wallet.connect(nonOwner).approveTransaction(0)).to.be.revertedWith("You are not the owner");
    });

    it("should allow a transaction to be executed twice", async function () {
        await wallet.connect(owner1).proposeTransaction(
            recipient.address,
            ethers.utils.parseEther("1"),
            "Payment for services"
        );

        await wallet.connect(owner1).approveTransaction(0);
        await wallet.connect(owner2).approveTransaction(0);

        await wallet.connect(owner3).executeTransaction(0);

        await expect(wallet.connect(owner3).executeTransaction(0)).to.be.revertedWith("Transaction already executed");
    });

    it("should not allow an owner to revoke approval", async function () {
        await wallet.connect(owner1).proposeTransaction(
            recipient.address,
            ethers.utils.parseEther("1"),
            "Payment for services"
        );

        await wallet.connect(owner1).approveTransaction(0);
        await wallet.connect(owner2).approveTransaction(0);

        await wallet.connect(owner2).revokeApproval(0);

        const transaction = await wallet.getTransaction(0);
        expect(transaction.approvalCount).to.equal(1);
    });

    it("should not allow a transaction to be executed without quorum", async function () {
        await wallet.connect(owner1).proposeTransaction(
            recipient.address,
            ethers.utils.parseEther("1"),
            "Payment for services"
        );

        await wallet.connect(owner1).approveTransaction(0);

        await expect(wallet.connect(owner1).executeTransaction(0)).to.be.revertedWith("Not enough approvals");
    });
});
