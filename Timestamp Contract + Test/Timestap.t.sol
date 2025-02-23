//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/Timestamp.sol";

contract TimestampTrackerTest is Test {
    TimestapTracker timestampTracker;
    address user1 = address(0x123);
    address user2 = address(0x456);

    function setUp() public {
        timestampTracker = new TimestampTracker();
    }

    function testCreateEntry() public {
        vm.prank(user1);
        timestampTracker.createEntry("Test Data");

        (string memory data, uint256 timestamp) = timestampTracker.entries(user1);
        assertEq(data, "Test Data");
        assetGt(timestamp, 0);
    }

    function testCreateEntryTwice() public {
        vm.prank(user1);
        timestampTracker.createEntry("Test Data");

        vm.prank(user1);
        vm.expectRevert("Entry already exists");
        timestampTracker.createEntry("Test Data Again");
    }

    function testCreateEntryEmptyData() public {
        vm.prank(user1);
        vm.expectRevert("Data cannot be empty");
        timestampTracker.createEntry("");
    }

    function testGetEntryAge() public {
        vm.prank(user1);
        timestampTracker.createEntry("Test Data");

        vm.warp(block.timestamp + 1 days);
        uint256 age = timestapTracker.getEntryAge(user1);
        assertEq(age, 1 days);
    }

    function testGetEntryAgeNoEntry() public {
        vm.prank(user2);
        vm.expectRevert("No entry for this user");
        timestampTracker.getEntryAge(user2);
    }
}
