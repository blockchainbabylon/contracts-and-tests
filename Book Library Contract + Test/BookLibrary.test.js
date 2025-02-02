const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleBookLibrary", function () {
  let SimpleBookLibrary;
  let library;
  let owner;
  let user1;
  let user2;
  let bookId;

  beforeEach(async function () {
    SimpleBookLibrary = await ethers.getContractFactory("SimpleBookLibrary");
    [owner, user1, user2] = await ethers.getSigners();

    library = await SimpleBookLibrary.deploy();
    await library.deployed();
  });

  it("should set the owner correctly", async function () {
    expect(await library.owner()).to.equal(owner.address);
  });

  it("should add a new book", async function () {
    await expect(library.addBook("Moby Dick", "Herman Melville", 3))
      .to.emit(library, "BookAdded")
      .withArgs(0, "Moby Dick");

    const book = await library.books(0);
    expect(book.title).to.equal("Moby Dick");
    expect(book.author).to.equal("Herman Melville");
    expect(book.copies).to.equal(3);

    bookId = 0;
  });

  it("should not allow non-owner to add a book", async function () {
    await expect(
      library.connect(user1).addBook("1984", "George Orwell", 2)
    ).to.be.revertedWith("Only owner can add books.");
  });

  it("should borrow a book successfully", async function () {
    await library.addBook("War and Peace", "Leo Tolstoy", 5);

    await library.connect(user1).borrowBook(1);

    const borrowed = await library.borrowedBooks(user1.address, 1);
    expect(borrowed).to.be.true;

    const book = await library.books(1);
    expect(book.copies).to.equal(4);

    await expect(library.connect(user1).borrowBook(1))
      .to.emit(library, "BookBorrowed")
      .withArgs(user1.address, 1);
  });

  it("should not allow borrowing a book more than once", async function () {
    await library.addBook("To Kill a Mockingbird", "Harper Lee", 2);

    await library.connect(user1).borrowBook(2);

    await expect(
      library.connect(user1).borrowBook(2)
    ).to.be.revertedWith("You have already borrowed this book.");
  });

  it("should return a borrowed book", async function () {
    await library.addBook("Pride and Prejudice", "Jane Austen", 3);

    await library.connect(user1).borrowBook(3);

    await expect(library.connect(user1).returnBook(3))
      .to.emit(library, "BookReturned")
      .withArgs(user1.address, 3);

    const borrowed = await library.borrowedBooks(user1.address, 3);
    expect(borrowed).to.be.false;

    const book = await library.books(3);
    expect(book.copies).to.equal(4);
  });

  it("should not allow returning a book not borrowed", async function () {
    await library.addBook("The Great Gatsby", "F. Scott Fitzgerald", 4);

    await expect(
      library.connect(user1).returnBook(4)
    ).to.be.revertedWith("You have not borrowed this book.");
  });

  it("should view a book's details", async function () {
    await library.addBook("The Catcher in the Rye", "J.D. Salinger", 2);

    const [title, author, copies] = await library.viewBook(4);
    expect(title).to.equal("The Catcher in the Rye");
    expect(author).to.equal("J.D. Salinger");
    expect(copies).to.equal(2);
  });
});
