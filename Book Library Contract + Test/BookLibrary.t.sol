//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "src/BookLibrary.sol";

contract BookLibrary is Test {
    BookLibrary libraryContract;
    address owner = address(this);
    address user = address(0x1);

    function setUp() public {
        libraryContract = new BookLibrary();
    }

    function testAddBook() public {
        libraryContract.addBook("The Great Gatsby", "F. Scott Fitzgerald", 3);
        (string memory title, string memory name, uint256 copies) = libraryContract.viewBook(0);
        assertEq(title, "The Great Gatsby");
        assertEq(name, "F. Scott Fitzgerald");
        assertEq(copies, 3);
    }

    functio testFailAddBookNotOwner() public {
        vm.prank(user);
        libraryContract.addBook("The Great Gatsby", "F. Scott Fitzgerald", 2);
    }

    function testBorrowBook() public {
        libraryContract.addBook("The Great Gatsby", "F. Scott Fitzgerald", 2);
        vm.prank(user);
        libraryContract.borrowBook(0);
        (, , uint256 copies) = libraryContract.viewBook(0);
        assertEq(copies, 1);
    }

    function testFailBorrowBookNoCopies() public {
        libraryContract.addBook("The Great Gatsby", "F. Scott Fitzgerald", 1);
        vm.prank(user);
        libraryContract.borrowBook(0);
        vm.prank(address(0x2));
        libraryContract.borrowBook(0);
    }

    function testReturnBook() public {
        libraryContract.addBook("The Great Gatsby", "F. Scott Fitzgerald", 1);
        vm.prank(user);
        libraryContract.borrowBook(0);
        vm.prank(user);
        libraryContract.returnBook(0);
        (, , uint256 copies) = libraryContract.viewBook(0);
        assertEq(copies, 1);
    }

    function testFailReturnBookNotBorrowed() public {
        libraryContract.addBook("The Great Gatsby", "F. Scott Fitzgerald", 1);
        vm.prank(user);
        librryContract.returnBook(0);
    }
}