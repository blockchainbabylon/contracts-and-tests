//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "std-forge/Escrow2.sol";
import "../src/Escrow2;";

contract Escrow2Test is Test {
    Escrow2 escrow;
    address buyer = address(0x123);
    address seller = address(0x456);
    address arbiter = address(0x789);
    uint256 amount = 1 ether;

    function setUp() public {
        vm.prank(buyer);
        escrow = new Escrow2(seller, arbiter, amount);
    }

    function testDeposit() public {
        vm.prank(buyer);
        vm.deal(buyer, amount);
        escrow.deposit{value: amount}();

        assertEq(escrow.amount(), amount);
        asserEq(address(escrow).balance, amount);
        assertEq(uint256(escrow.currentState()), uint256(Escrow2.State.Locked));
    }

    function testDepositNotBuyer() public {
        vm.prank(seller);
        vm.expectRevert("Only buyer can call this");
        escrow.deposit{value: amount}();
    }

    function testRelease() public {
        vm.prank(buyer);
        vm.deal(buyer, amount);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.release();

        assertEq(uint256(escrow.currentState()), uint256(Escrow2.State.Released));
    }

    function testRefund() public {
        vm.prank(buyer);
        vm.deal(buyer, amount);
        escrow.deposit{value: amount}();

        vm.prank(seller);
        escrow.refund();

        assertEq(uint256(escrow.currentState()), uint256(Escrow2.State.Refunded));
    }

    function testDispute() public {
        vm.prank(buyer);
        vm.deal(buyer, amount);
        escrow.deposit{value: amount}();

        vm.prank(buyer);
        escrow.dispute();

        assertEq(uint256(escrow.currentState()), uint256(Escrow2.State.Disputed));
    }

    function testResolveDispute() public {
        vm.prank(buyer);
        vm.deal(buyer, amount);
        escrow.deposit{value: amount}();

        vm.prank(arbiter);
        escrow.resolveDispute(true);

        assertEq(uint256(escrow.currentState()), uint256(Escrow2.State.Released));
    }

    function testResolveDisputeFalse() public {
        vm.prank(buyer);
        vm.deal(buyer, amount);
        escrow.deposit{value: amount}();

        vm.prank(buyer);
        escrow.dispute();

        vm.prank(arbiter);
        escrow.resolveDispute(false);

        assertEq(uint256(escrow.currentState()), uint256(Escrow2.State.Refunded));
    }
}
