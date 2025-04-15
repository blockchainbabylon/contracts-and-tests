const { expect } = require("chai");

describe("DecentrailzedGiftRegistry", function () {
    let GiftRegistry, giftRegistry;
    let owner, user1, user2;

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();

        GiftRegistry = await ethers.getContracyFactory("DecentralizedGiftRegistry");
        giftRegistry = await GiftRegistry.deploy();
        await giftRegistry.deployed();
    });

    it("should allow a user to create a registry", async function () {
        const tx = await giftRegistry.connect(user1).createRegistry();
        const receipt = await tx.wait();
        const registryId = receipt.events[0].args.registryId;

        const registries = await giftRegistry.getMyRegistries({ from: user1.address });
        expect(registries.length).to.equal(1);
        expect(registries[0]).to.equal(registryId);

        const registryOwner = await giftRegistry.registryOwners(registryId);
        expect(registryOwner).to.equal(user1.address);
    });

    it("should allow a registry owner to add a gift", async function () {
        const tx = await giftRegistry.connect(user1).createRegistry();
        const receipt = await tx.wait();
        const registryId = receipt.events[0].args.registryId;

        await giftRegistry.connect(user1).addGift(registryId, "Gift1", "Description1", ethers.utils.parseEther("1"));
        
        const gifts = await giftRegistry.getRegistryGifts(registryId);
        expect(gifts.length).to.equal(1);
        expect(gifts[0].name).to.equal("Gift1");
        expect(gifts[0].price).to.equal(ethers.utisl.parseEther("1"));
    });

    it("should allow a user to reserve a gift", async function () {
        const tx = await giftRegistry.connect(user1).createRegistry();
        const receipt = await tx.wait();
        const registryId = receipt.events[0].args.registryId;

        await giftRegistry.connect(user1).addGift(registryId, "Gift1", "Description1", ethers.utils.parseEther("1"));

        const gifts = await giftRegistry.getRegistryGifts(registryId);
        const giftId = gifts[0].id;

        await giftRegistry.connect(user2).reserveGift(giftId);

        const reservedGift = await giftRegistry.getGiftDetails(giftId);
        expect(reservedGift.reservedBy).to.equal(user2.address);
    });

    it("should allow a user to purchase a reserved gift", async function () {
        const tx = await giftRegistry.connect(user1).createRegistry();
        const receipt = await tx.wait();
        const registryId = receipt.events[0].args.registryId;

        await giftRegistry.connect(user1).addGift(registryId, "Gift1", "Description1", ethers.utils.parseEther("1"));

        const gifts = await giftRegistry.getRegistryGifts(registryId);
        const giftId = gifts[0].id;

        await giftRegistry.connect(user2).reserveGift(giftId);

        await user2.sendTransaction({
            to: giftRegistry.address,
            value: ethers.utils.parseEther("1"),
        });

        await giftRegistry.connect(user2).purchaseGift(giftId, { value: ethers.utils.parseEther("1") });

        const purchasedGift = await giftRegistry.getGiftDetails(giftId);
        expect(purchasedGift.purchased).to.be.true;
    });

    it("should not allow a user to reserve an already reserved gift", async function () {
        const tx = await giftRegistry.connect(user1).createRegistry();
        const receipt = await tx.wait();
        const registryId = receipt.events[0].args.registryId;

        await giftRegistry.connect(user1).addGift(registryId, "Gift1", "Description1", ethers.utils.parseEther("1"));

        const gifts = await giftRegistry.getRegistryGifts(registryId);
        const giftId = gifts[0].id;

        await giftRegistry.connect(user2).reserveGift(giftId);

        await expect(giftRegistry.connect(user1).reserveGift(giftId)).to.be.revertedWith("Gift already reserved");
    });

    it("should now allow a user to purchase an unreserved gift", async function () {
        const tx = await giftRegistry.connect(user1).createRegistry();
        const receipt = await tx.wait();
        const registryId = receipt.events[0].args.registryId;

        await giftRegistry.connect(user1).addGift(registryId, "Gift1", "Description1", ethers.utils.parseEther("1"));

        const gifts = await giftRegistry.getRegistryGifts(registryId);
        const giftId = gifts[0].id;

        await expect(
            giftRegistry.connect(user2).purchaseGift(giftId, { value: ethers.utils.parseEther("1") })
        ).to.be.revertedWith("Gift must be reserved before purchase");
    });

    it("should allow a registry owner to remove a gift", async function () {
        const tx = await giftRegistry.connect(user1).createRegistry();
        const receipt = await tx.wait();
        const registryId = receipt.events[0].args.registryId;

        await giftRegistry.connect(user1).addGift(registryId, "Gift1", "Description1", ethers.utils.parseEther("1"));

        const gifts = await giftRegistry.getRegistryGifts(registryId);
        const giftId = gifts[0].id;

        await giftRegistry.connect(user1).removeGift(registryId, giftId);

        const updatedGifts = await giftRegistry.getRegistryGifts(registryId);
        expect(updatedGifts.length).to.equal(0);
    });
});
