// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address owner1 = address(0x123);
    address owner2 = address(0x456);
    address owner3 = address(0x789);
    address nonOwner = address(0xABC);
    address recipient = address(0xDEF);
    uint256 quorum = 2;

    function setUp() public {
        address[] memory initialOwners = new address[](3);
        initialOwners[0] = owner1;
        initialOwners[1] = owner2;
        initialOwners[2] = owner3;

        vm.prank(owner1);
        wallet = new MultiSigWallet(initialOwners, quorum);

        // Fund the wallet with Ether
        vm.deal(address(wallet), 10 ether);
    }

    function testInitializeWallet() public {
        assertEq(wallet.getOwnersCount(), 3);
        assertEq(wallet.quorum(), quorum);
        assertEq(wallet.getOwner(0), owner1);
        assertEq(wallet.getOwner(1), owner2);
        assertEq(wallet.getOwner(2), owner3);
    }

    function testProposeTransaction() public {
        vm.prank(owner1);
        wallet.proposeTransaction(recipient, 1 ether, "Test Transaction");

        (address to, uint256 amount, string memory description, bool executed, uint256 approvalCount) = wallet.getTransaction(0);

        assertEq(to, recipient);
        assertEq(amount, 1 ether);
        assertEq(description, "Test Transaction");
        assertFalse(executed);
        assertEq(approvalCount, 0);
    }

    function testApproveTransaction() public {
        vm.prank(owner1);
        wallet.proposeTransaction(recipient, 1 ether, "Test Transaction");

        vm.prank(owner1);
        wallet.approveTransaction(0);

        vm.prank(owner2);
        wallet.approveTransaction(0);

        (, , , , uint256 approvalCount) = wallet.getTransaction(0);
        assertEq(approvalCount, 2);
    }

    function testExecuteTransaction() public {
        vm.prank(owner1);
        wallet.proposeTransaction(recipient, 1 ether, "Test Transaction");

        vm.prank(owner1);
        wallet.approveTransaction(0);

        vm.prank(owner2);
        wallet.approveTransaction(0);

        uint256 recipientInitialBalance = recipient.balance;

        vm.prank(owner3);
        wallet.executeTransaction(0);

        uint256 recipientFinalBalance = recipient.balance;
        assertEq(recipientFinalBalance, recipientInitialBalance + 1 ether);

        (, , , bool executed, ) = wallet.getTransaction(0);
        assertTrue(executed);
    }

    function testCannotExecuteWithoutQuorum() public {
        vm.prank(owner1);
        wallet.proposeTransaction(recipient, 1 ether, "Test Transaction");

        vm.prank(owner1);
        wallet.approveTransaction(0);

        vm.prank(owner3);
        vm.expectRevert("Not enough approvals");
        wallet.executeTransaction(0);
    }

    function testRevokeApproval() public {
        vm.prank(owner1);
        wallet.proposeTransaction(recipient, 1 ether, "Test Transaction");

        vm.prank(owner1);
        wallet.approveTransaction(0);

        vm.prank(owner2);
        wallet.approveTransaction(0);

        vm.prank(owner2);
        wallet.revokeApproval(0);

        (, , , , uint256 approvalCount) = wallet.getTransaction(0);
        assertEq(approvalCount, 1);
    }

    function testAddOwner() public {
        address newOwner = address(0xAAA);

        vm.prank(owner1);
        wallet.addOwner(newOwner);

        assertEq(wallet.getOwnersCount(), 4);
        assertEq(wallet.getOwner(3), newOwner);
    }

    function testRemoveOwner() public {
        vm.prank(owner1);
        wallet.removeOwner(owner3);

        assertEq(wallet.getOwnersCount(), 2);
        assertEq(wallet.getOwner(0), owner1);
        assertEq(wallet.getOwner(1), owner2);
    }

    function testSetQuorum() public {
        vm.prank(owner1);
        wallet.setQuorum(3);

        assertEq(wallet.quorum(), 3);
    }

    function testCannotProposeTransactionAsNonOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("You are not the owner");
        wallet.proposeTransaction(recipient, 1 ether, "Test Transaction");
    }

    function testCannotApproveTransactionAsNonOwner() public {
        vm.prank(owner1);
        wallet.proposeTransaction(recipient, 1 ether, "Test Transaction");

        vm.prank(nonOwner);
        vm.expectRevert("You are not the owner");
        wallet.approveTransaction(0);
    }
}
