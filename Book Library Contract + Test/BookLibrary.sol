// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleBookLibrary {
    address public owner;
    
    struct Book {
        string title;
        string author;
        uint256 copies;
    }
    
    mapping(uint256 => Book) public books;
    mapping(address => mapping(uint256 => bool)) public borrowedBooks; // Tracks which books a user has borrowed
    uint256 public bookCounter; //Counter to keep track of books added

    event BookAdded(uint256 bookId, string title);
    event BookBorrowed(address indexed borrower, uint256 bookId);
    event BookReturned(address indexed borrower, uint256 bookId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can add books.");
        _;
    }

    modifier bookExists(uint256 bookId) {
        require(bytes(books[bookId].title).length > 0, "Book does not exist.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Add a new book (only owner can add)
    function addBook(string memory title, string memory author, uint256 copies) public onlyOwner {
        require(copies > 0, "Cannot add a book with zero copies.");
        
        books[bookCounter] = Book(title, author, copies); // Directly use bookCounter here
        emit BookAdded(bookCounter, title);
        
        bookCounter++; // Increment for the next book to be added
    }

    function borrowBook(uint256 bookId) public bookExists(bookId) {
        require(books[bookId].copies > 0, "No copies available.");
        require(!borrowedBooks[msg.sender][bookId], "You have already borrowed this book.");

        books[bookId].copies--;
        borrowedBooks[msg.sender][bookId] = true;
        emit BookBorrowed(msg.sender, bookId);
    }

    function returnBook(uint256 bookId) public bookExists(bookId) {
        require(borrowedBooks[msg.sender][bookId], "You have not borrowed this book.");

        books[bookId].copies++;
        borrowedBooks[msg.sender][bookId] = false;
        emit BookReturned(msg.sender, bookId);
    }

    function viewBook(uint256 bookId) public view bookExists(bookId) returns (string memory title, string memory author, uint256 copies) {
        Book memory book = books[bookId];
        return (book.title, book.author, book.copies);
    }
}
