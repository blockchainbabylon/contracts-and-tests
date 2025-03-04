//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/TimeLockWallet3.sol";

contract TimeLockWalletTest is Test {
    TimeLockWallet3 wallet;
    address owner = address(0x123);
    address nonOwner = address(0x456);
    uint256 unlockTime = 1 days;

    function setUp() public {
        vm.prank(owner);
        wallet = new TimeLockedWallet3(unlockTime);
    }

    function testDeposit() public {
        vm.prank(owner);
        wallet.deposit{value: 1 ether}();

        assertEq(address(wallet).balance, 1 ether);
    }

    function testWithdrawal() public {
        vm.prank(owner);
        wallet.deposit{value: 1 ether}();

        vm.warp(block.timestamp + unlockTime + 1);

        vm.prank(owner);
        wallet.withdrawal(1 ether);

        assertEq(address(wallet).balance, 0);
    }

    function testWithdrawalBeforeUnlock() public {
        vm.prank(owner);
        wallet.deposit{value: 1 ether}();

        vm.expectRevert("Sorry your funds are still locked");
        vm.prank(owner);
        wallet.withdrawal(1 ether);
    }

    function testWithdrawalNotOwner() public {
        vm.prank(owner);
        wallet.deposit{value: 1 ether}();

        vm.warp(block.timestamp + unlockTime + 1);

        vm.expectRevert("Sorry, you are not the owner");
        vm.prank(nonOwner);
        vm.withdrawal(1 ether);
    }

    function testGetTimeLeft() public {
        uint256 timeLeft = wallet.getTimeLeft();
        assertEq(timeLeft, unlockTime);

        vm.warp(block.timestamp + unlockTime / 2);
        timeLeft - wallet.getTimeLeft();
        assertEq(timeLeft, unlockTime / 2);

        vm.warp(block.timestamp + unlockTime / 2 + 1);
        timeLeft = wallet.getTimeLeft();
        assertEq(timeLeft, 0);
    }
}
