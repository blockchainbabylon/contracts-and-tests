//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/GiftRegistry.sol";

contract DecentralizedGiftRegistryTest is Test {
    DecentralizedGiftRegistry giftRegistry;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);

    function setUp() public {
        vm.prank(owner);
        giftRegistry = new DecentraliedGiftRegistry();
    }

    function testCreateRegistry() public {
        vm.prank(user1);
        uint256 registryId = giftRegistry.createRegistry();

        uint256[] memory registries = giftRegistry.getMyRegistries();
        assertEq(registries.length, 1);
        assertEq(registries[0], registryId);

        address registryOwner = giftRegistry.registryOwner(registryId);
        assertEq(registryOwner, user1);
    }

    function testAddGift() public {
        vm.prank(user1);
        uint256 registryId = giftRegistry.createRegistry();

        vm.prank(user1);
        giftRegistry.addGift(registryId, "Gift1", "Description1", 1 ether);

        GiftRegistry.Gift[] memory gifts = giftRegistry.getRegistryGifts(registryId);
        assertEq(gifts.length, 1);
        assertEq(gifts[0].name, "Gift1");
        assertEq(gifts[0].price, 1 ether);
    }

    function testReserveGift() public {
        vm.prank(user1);
        uint256 registryId = giftRegistry.createRegistry();

        vm.prank(user1);
        giftRegistry.addGift(registryId, "Gift1", "Description1", 1 ether);

        GiftRegistry.Gift[] memory gifts = giftRegistry.getRegistryGifts(registryId);
        uint256 giftId = gifts[0].id;

        vm.prank(user2);
        giftRegistry.reserveGift(giftId);

        GiftRegistry.Gift memory reservedGift = giftRegistry.getGiftDetails(giftId);
        assertEq(reservedGift.reservedBy, user2);
    }

    function testPurchaseGift() public {
        vm.prank(user1);
        uint256 registryId = giftRegistry.createRegistry();

        vm.prank(user1);
        giftRegistry.addGift(registryId, "Gift1", "Description1", 1 ether);

        GiftRegistry.Gift[] memory gifts = giftRegistry.getRegistryGifts(registryId);
        uint256 giftId = gifts[0].id;

        vm.prank(user2);
        giftRegistry.reserveGift(giftId);

        vm.deal(user2, 2 ether);
        vm.prank(user2);
        giftRegistry.purchaseGift{value: 1 ether}(giftId);

        GiftRegistry.Gift memory purchasedGift = giftRegistry.getGiftDetails(giftId);
        assertTrue(purchasedGift.purchased);
    }

    function testCannotReserveAlreadyReservedGift() public {
        vm.prank(user1);
        uint256 registryId = giftRegistry.createRegistry();

        vm.prank(user1);
        giftRegistry.addGift(registryId, "Gift1", "Description1", 1 ether);

        GiftRegistry.Gift[] memory gifts = giftRegistry.getRegistryGifts(registryId);
        uint256 giftId = gifts[0].id;

        vm.prank(user2);
        giftRegistry.reserveGift(giftId);

        vm.prank(user1);
        vm.expectRevert("Gift already reserved");
        giftRegistry.reserveGift(giftId);
    }

    function testCannotPurchaseUnreservedGift() public {
        vm.prank(user1);
        uint256 registryId = giftRegistry.createRegistry();

        vm.prank(user1);
        giftRegistry.addGift(registryId, "Gift1", "Description1", 1 ether);

        GiftRegistry.Gift[] memory gifts = giftRegistry.getRegistryGifts(registryId);
        uint256 giftId = gifts[0].id;

        vm.deal(user2, 2 ether);
        vm.prank(user2);
        vm.expectRevert("Gift must be reserved before purchase");
        giftRegistry.purchaseGift{value: 1 ether}(giftId);
    }

    function testRemoveGift() public {
        vm.prank(user1);
        uint256 registryId = giftRegistry.createRegistry();

        vm.prank(user1);
        giftRegistry.addGift(registryId, "Gift1", "Description1", 1 ether);

        GiftRegistry.Gift[] memory gifts = giftRegistry.getRegistryGifts(registryId);
        uint256 giftId = gifts[0].id;

        vm.prank(user1);
        giftRegistry.removeGift(registryId, giftId);

        GiftRegistry.Gift[] memory updatedGifts = giftRegistry.getRegistryGifts(registryId);
        assertEq(updatedGifts.length, 0);
    }
}
