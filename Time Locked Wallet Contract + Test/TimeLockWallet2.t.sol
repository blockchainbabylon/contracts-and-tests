//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/TimeLockWallet2.sol";

contract TimeLockTest is Test {
    TimeLockWallet2 timeLock;
    address owner = address(0x123);
    address user1 = address(0x456);
    uint256 unlockTime = 1 days;

    function setUp() public {
        vm.prank(owner);
        timeLock = new TimeLockWallet2(unlockTime);

        vm.deal(user1, 3 ether);
    }

    function shouldAllowDeposit() public {
        vm.prank(user1);
        timeLock.deposit{ value: 1 ether}();

        assertEq(timeLock.balance(), 1 ether);
    }

    function revertWhenDepositIsZero() public {
        vm.prank(user1);
        vm.expectRevert("Need to deposit more than zero");
        timeLock.deposit{ value: 0 }();
    }

    function testOnlyOwnerApproval() public {
        vm.prank(owner);
        timeLock.approveWithdrawalsByOwner();
        assertTrue(timeLock.ownerApproval());
    }

    function shouldRevertIfNotOwnerTryingToApprove() public {
        vm.prank(user1);
        vm.expectRevert("Sorry, you are not the owner");
        timeLock.approveWithdrawalsByOwner();
    }

    function allowWithdrawal() public {
        vm.prank(user1);
        timeLock.deposit{ value: 1 ether }();
        assertEq(timeLock.balance(), 1 ether);

        vm.prank(owner);
        timeLock.approveWithdrawalsByOwner();
        assertTrue(timeLock.ownerApproval());

        vm.warp(block.timestamp + 2 days);

        uint256 user1Initial = user1.balance;
        vm.prank(user1);
        string memory result = timeLock.withdraw(1 ether);
        assertEq(result, "Withdrawal successful");

        assertEq(timeLock.balance(), 0);
        assertEq(user1.balance, userInitial + 1 ether);

        assertFalse(timeLock.ownerApproval());
    }

    function testRevertWithdrawBeforeUnlock() public {
        vm.prank(user1);
        timeLock.deposit{ value: 1 ether }();

        vm.prank(owner);
        timeLock.approveWithdrawalsByOwner();

        vm.prank(user1);
        vm.expectRevert("You have to wait until funds are allowed to be unlocked");
        timeLock.withdraw(1 ether);
    }

    function testRevertWithdrawWithoutApproval() public {
        vm.prank(user1);
        timeLock.deposit{ value: 1 ether }();

        vm.warp(block.timestamp + 2 days);

        vm.prank(user1);
        vm.expectRevert("Owner has not approved withdrawals");
        timeLock.withdraw(1 ether);
    }

    function testRevertWithdrawNoFunds() public {
        vm.prank(owner);
        timeLock.approveWithdrawalsByOwner();

        vm.warp(block.timestamp + 2 days);

        vm.prank(user1);
        vm.expectRevert("No funds held on the contract");
        timeLock.withdraw(1 ether);
    }
}
