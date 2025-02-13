//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/Wallet.sol";

contract WalletTest is Test {
    Wallet wallet;
    address owner = address(this);
    address nonOwner = address(0x123);

    function setUp() public {
        wallet = new Wallet();
    }

    function testOwnerIsDeployer() public {
        assertEq(wallet.owner(), owner);
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        vm.deal(address(this), depositAmount);
        
        wallet.deposit{value: depositAmount}();
        
        assertEq(wallet.getBalance(), depositAmount);
    }

    function testWithdrawAsOwner() public {
        uint256 depositAmount = 2 ether;
        uint256 withdrawAmount = 1 ether;

        vm.deal(address(this), depositAmount);
        wallet.deposit{value: depositAmount}();

        uint256 beforeBalance = address(this).balance;
        wallet.withdraw(withdrawAmount);
        uint256 afterBalance = address(this).balance;

        assertEq(afterBalance, beforeBalance + withdrawAmount);
        assertEq(wallet.getBalance(), depositAmount - withdrawAmount);
    }

    function testFailWithdrawByNonOwner() public {
        vm.prank(nonOwner);
        wallet.withdraw(1 ether);
    }

    function TestFailWithdrawInsufficientFuncds() public {
        wallet.withdraw(1 ether);
    }

    receive() external payable {}
}