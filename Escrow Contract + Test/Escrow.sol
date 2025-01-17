//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    bool public buyerApproved;
    bool public sellerApproved;
    bool public transactionCompleted;

    event Deposit(address indexed buyer, uint256 amount);
    event Approved(address indexed party);
    event Released(address indexed arbiter, uint256 amount);
    event Refunded(address indexednarbiter, uint256 amount);

    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
    }

    function deposit() public payable {
        require(buyer == msg.sender, "You are not the buyer");
        require(msg.value > 0, "Have to deposit more than zero");
        require(amount == 0, "Amount already deposited");
        amount = msg.value;

        emit Deposit(buyer, msg.value);
    }

    function approveByBuyer() external {
        require(msg.sender == buyer, "Only buyer can approve");
        require(amount > 0, "No funds deposited");
        buyerApproved = true;

        emit Approved(buyer);
    }

    function approveBySeller() external {
        require(msg.sender == seller, "Only seller can approve");
        require(amount > 0, "No funds deposited");
        sellerApproved = true;

        emit Approved(seller);
    }

    function release() external {
        require(msg.sender == arbiter, "Only arbiter can release funds");
        require(buyerApproved && sellerApproved, "Both parties must approve");
        require(!transactionCompleted, "Transaction already completed");
        transactionCompleted = true;
        payable(seller).transfer(amount);

        emit Released(arbiter, amount);
    }

    function refund() external {
        require(msg.sender == arbiter, "Only arbiter can refund");
        require(!transactionCompleted, "Transaction already completed");
        require(!buyerApproved || !sellerApproved, "Both parties approved");

        transactionCompleted = true;
        payable(buyer).transfer(amount);

        emit Refunded(arbiter, amount);
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }
}