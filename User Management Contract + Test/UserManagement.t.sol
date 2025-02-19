//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "std-forge/Test.sol";
import "../src/UserManagement.sol";

contract UserManagement is Test {
    UserManagement userManagement;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);

    function setUp() public {
        vm.prank(owner);
        userManagement = new UserManagement();
    }

    function testAddUser() public {
        vm.prank(owner);
        userManagement.addUser(user1, "Alice", 1000);

        (string memory name, uint256 balance) = userManagement.getUserInfo(user1);
        assertEq(name, "Alice");
        assertEq(balance, 1000);
        assertEq(userManagement.getTotalUsers(), 1);
    }

    function testAddUserNotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Sorry, you are not the owner");
        userManagement.addUser(user2, "Bob", 500);
    }

    function testUpdateUserBalance() public {
        vm.prank(owner);
        userManagement.addUser(user1, "Alice", 1000);

        vm.prank(owner);
        userManagement.updateUserBalance(user1, 2000);

        (, uint256 balance) = userManagement.getUserInfo(user1);
        assertEq(balance, 2000);
    }

    function testUpdateUserBalanceNotOwner() public {
        vm.prank(owner);
        userManagement.addUser(user1, "Alice", 1000);

        vm.prank(user1);
        vm.expectRevert("Sorry, you are not the owner");
        userManagement.updateUserBalance(user1, 2000);
    }    

    function testGetUserInfo() public {
        vm.prank(owner);
        userManagement.addUser(user1, "Alice", 1000);

        (string memory name, uint256 balance) = userManagement.getUserInfo(user1);
        assertEq(name, "Alice");
        assertEq(balance, 1000);
    }

    function testGetTotalUsers() public {
        vm.prank(owner);
        userManagement.addUser(user1, "Alice", 1000);
        userManagement.addUser(user2, "Bob", 500);

        assertEq(userManagement.getTotalUsers(), 2);
    }
}