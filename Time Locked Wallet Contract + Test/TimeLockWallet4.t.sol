//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// /\_/\  
//( o.o ) 
// > ^ <

import "forge-std/Test.sol";
import "../src/TimeLockWallet4.sol";

contract TimeLockWalletTest is Test {
    TimeLockWallet4 wallet;
    address owner = address(0x123);
    address nonOwner = address(0x456);
    uint256 unlockTime = 1 days;

    function setUp() public {
        wallet = new TimeLockWallet4();
    }

    function testDeposit() public {
        vm.prank(owner);
        wallet.deposit{value: 1 ether}(unlockTime);

        assertEq(address(wallet).balance, 1 ether);
        assertEq(wallet.deposited(owner), 1 ether);
        assertEq(wallet.unlockTimes(owner), block.timestamp + unlockTime);
    }

    function testWithdrawal() public {
        vm.prank(owner);
        wallet.deposit{value: 1 ether}(unlockTime);

        vm.warp(block.timestamp + unlockTime + 1);

        vm.prank(owner);
        wallet.withdrawal();

        assertEq(address(wallet).balance, 0);
        assertEq(wllet.deposited(owner), 0);
        assertEq(wallet.unlockTimes(owner), 0);
    }

    function testWithdrawalBeforeUnlock() public {
        vm.prank(owner);
        wallet.deposit{value: 1 ether}(unlockTime);

        vm.expectRevert("Funds are still locked");
        vm.prank(owner);
        wallet.withdrawal();
    }

    function testWithdrawalNotOwner() public {
        vm.prank(owner);
        wallet.deposit{value: 1 ether}(unlockTime);

        vm.warp(block.timestamp + unlockTime + 1);

        vm.expectRevert("You have nothing to withdraw");
        vm.prank(nonOwner);
        wallet.withdrawal();
    }

    function testGetTimeLeft() public {
        vm.prank(owner);
        wallet.deposit{value: 1 ether}(unlockTime);

        uint256 timeLeft = wallet.unlockTimes(owner) - block.timestamp;
        assertEq(timeLeft, unlockTime);

        vm.warp(block.timestamp + unlockTime / 2);
        timeLeft = wallet.unlockTimes(owner) - block.timestamp;
        assertEq(timeLeft, unlockTime / 2);

        vm.warp(block.timestamp + unlockTime / 2 + 1);
        timeLeft = wallet.unlockTimes(owner) - block.timestamp;
        assertEq(timeLeft, 0);
    }


}