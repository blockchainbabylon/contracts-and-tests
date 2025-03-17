//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/Escrow3.sol";

contract EscrowTest is Test {
    Escrow escrow;
    address buyer = address(0x123);
    address seller = address(0x456);
    address arbiter = address(0x789);
    address amount = 1 ether;

    function setUp() public {
        vm.prank(buyer);
        escrow = new Escrow(amount, arbiter);
        escrow.seller() = seller;
    }

    function testDeposit() public {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        assertEq(escrow.balances(buyer), amount);
    }

    function testMarkShipped() public {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.markShipped();

        assertTrue(escrow.shipped());
    }

    function testReleaseFunds() public {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.markShipped();

        vm.prank(buyer);
        escrow.releaseFunds();

        assertEq(escrow.balances(buyer), 0);
        assertEq(seller.balance, amount);
    }

    function testCancelTransaction() public {
        vm.prank(buyer);
        escrow.deposit{value: amount}();
        
        vm.prank(buyer);
        escrow.cancelTransaction();

        assertEq(escrow.balances(buyer), 0);
        assertEq(buyer.balance, amount);
    }

    function testDisputeResolutionBuyer() public {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(arbiter);
        escrow.disputeResolution();

        assertEq(escrow.balances(buyer), 0);
        assertEq(buyer.balance, amount);
    }

    function testDisputeResolutionSeller() public {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.markShipped();

        vm.prank(arbiter);
        escrow.disputeResolution();

        assertEq(escrow.balances(seller), 0);
        assertEq(seller.balance, amount);
    }

    function testAutoReleaseFunds() public {
        vm.prank(buyer);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.markShipped();

        vm.prank(buyer);
        escrow.autoReleaseFunds();

        assertEq(escrow.balances(buyer), 0);
        assertEq(seller.balance, amount);
    }
}
