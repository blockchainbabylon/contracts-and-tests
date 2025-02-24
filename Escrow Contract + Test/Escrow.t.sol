//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "std-forge/Test.sol";
import "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow escrow;
    address buyer = address(0x123);
    address seller = address(0x456);
    address arbiter = address(0x789);

    function setUp() public {
        vm.prank(buyer);
        escrow = new Escrow(seller, arbiter);
    }

    function testDeposit() public {
        vm.prank(buyer);
        vm.deal(buyer, 1 ether);
        escrow.deposit{value: 1 ether}();

        assertEq(escrow.amount(), 1 ether); //checks amount from struct is same as deposit amount
        assertEq(addres(escrow).balance, 1 ether); //checks the balance address of the escrow contract
    }

    function testDepositNotBuyer() public {
        vm.prank(seller);
        vm.expectRevert("You are not the buyer");
        escrow.deposit{value: 1 ether}();
    }

    function testApproveByBuyer() public {
        vm.prank(buyer);
        vm.deal(buyer, 1 ether);
        escrow.deposit{value: 1 ether}();

        vm.prank(buyer);
        escrow.approveByBuyer();

        assertTrue(escrow.buyerApproved());
    }

    function testApproveByBuyerNotBuyer() public {
        vm.prank(seller);
        vm.expectRevert("Only buyer can approve");
        escrow.approveByBuyer();
    }

    function testApproveByBuyerNoFunds() public {
        vm.prank(buyer);
        vm.expectRevert("No funds deposited");
        escrow.approveByBuyer();
    }
}