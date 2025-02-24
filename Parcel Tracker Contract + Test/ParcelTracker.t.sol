//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "std-forge/Test.sol";
import "../src/ParcelTracker.sol";

contract ParcelTrackerTest is Test {
    ParcelTracker  parcelTracker;
    address owner = address(0x123);
    address recipient = address(0x456);

    function setUp() public {
        vm.prank(owner);
        parcelTracker = new ParcelTracker();
    }

    function testAddParcel() public {
        vm.prank(owner);
        parcelTracker.addParcel(recipient);

        (uint256 id, address parcelRecipient, ParcelTracker.DeliveryStatus status) = parcelTracker.parcels(1);
        assertEq(id, 1);
        assertEq(parcelRecipient, recipient);
        assertEq(uint256(status), uint256(ParcelTracker.DeliveryStatus.Pending));
        assertEq(parcelTracker.parcelCount(), 1);
    }

    function testAddParcelNotOwner() public {
        vm.prank(recipient);
        vm.expectRevert("You are not the owner");
        parcelTracker.addParcel(recipient);
    }

    function testUpdateStatus() public {
        vm.prank(owner);
        parcelTracker.addParcel(recipient);

        vm.prank(owner);
        parcelTracker.updateStatus(1, ParcelTracker.DeliveryStatus.Shipped);

        (, , ParcelTracker.DeliveryStatus status) = parcelTracker.parcels(1);
        assertEq(uint256(status), uint256(ParcelTracker.DeliveryStatus.Shipped));
    }

    function testUpdateStatusNotOwner() public {
        vm.prank(owner);
        parcelTracker.addParcel(recipient);

        vm.prank(recipient);
        vm.expectRevert("You are not the owner");
        parcelTracker.updateStatus(1, ParcelTracker.DeliveryStatus.Shipped);
    }
}