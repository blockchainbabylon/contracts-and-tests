//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/DeFiLending.sol";

contract LendingTest is Test {
    Lending lending;
    address user1 = address(0x123);
    address user2 = address(0x456);

    function setUp() public {
        lending = new Lending();
    }

    function testDeposit() public {
        vm.prank(user1);
        lending.deposit{value: 1 ether}();

        (uint256 deposit, , ) = lending.users(user1);
        assertEq(deposit, 1 ether); //checks correct amount is deposited
    }

    function testBorrow() public {
        vm.prank(user1);
        lendig.deposit{value: 1 ether}(); //deposit as user1

        vm.prank(user1);
        lending.borrow(0.5 ether); //user1 borrows

        ( , uint256 borrowed, ) = lending.users(user1);
        assertEq(borrowed, 0.5 ether); //checks borrowed amount of user1
    }

    function testRepay() public {
        vm.prank(user1);
        lending.deposit{value: 1 ether}();

        vm.prank(user1);
        lending.borrow(0.5 ether);

        vm.prank(user1);
        lending.repay{value: 0.5 ether}(); //repays borrowed amount

        (, uint256 borrowed, ) = lending.users(user1);
        assertEq(borrowed, 0); //checks borrowed amount after repay
    }

    function testLiquidate() public {
        vm.prank(user1);
        lending.deposit{value: 1 ether}();

        vm.prank(user1);
        lending.borrow(0.8 ether);

        vm.warp(block.timestamp + 365 days); //moves time forward to accrue interest

        vm.prank(user2);
        lending.liquidate(user1);

        (uint256 deposit, uint256 borrowed, ) = lending.users(user1);
        assertEq(deposit, 0); //amount liquidated
        assertEq(borrowed, 0); //amount liquidated
    }

    function testCannotBorrowWithoutCollateral() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient collateral");
        lending.borrow(0.5 ether); //tried to borrow without deposit
    }

    function testCannotRepayMoreThanBorrowed() public {
        vm.prank(user1);
        lending.deposit{value: 1 ether}();

        vm.prank(user1);
        lending.borrow(0.5 ether);

        vm.prank(user1);
        vm.expectRevert("Overpayment not allowed");
        lending.repay{value: 1 ether}(); //will revert due to trying to repay more than borrowed
    }

    function testCannotLiquidateWithSufficientCollateral() public {
        vm.prank(user1);
        lending.deposit{value: 1 ether}();

        vm.prank(user1);
        lending.borrow(0.5 ether);

        vm.prank(user2);
        vm.expectRevert("Cannot liquidate");
        lending.liquidate(user1); //
    }
}
