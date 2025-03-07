//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    uint256 public releaseTime;

    bool public shipped;
    mapping(address => uint256) public balances;

    constructor(uint256 _amount, address _arbiter) {
        buyer = msg.sender;
        amount = _amount;
        arbiter = _arbiter;
        releaseTime = block.timestamp + 30 days;
    }


    function deposit() public payable {
        require(msg.sender == buyer, "Sorry, you are not the buyer");
        require(msg.value == amount, "You must deposit the correct amount, nothing more, nothing less");

        balances[msg.sender] += amount;
    }

    function markShipped() public {
        require(msg.sender == seller, "Sorry, you are not the seller");
        shipped = true;
    }

    function releaseFunds() public {
        require(shipped, "Item has not been shipped");
        require(msg.sender == buyer, "Sorry, you are not the buyer");

        balances[buyer] -= amount;
        payable(seller).transfer(amount);
    }

    function cancelTransaction() public {
        require(msg.sender == buyer, "Sorry, you are not the buyer");
        require(!shipped, "Sorry, item already shipped");

        balances[buyer] -= amount;
        payable(buyer).transfer(amount);
    }

    function disputeResolution() public {
        require(msg.sender == arbiter, "Sorry, you are not the arbiter");
        
        if (!shipped) {
            balances[buyer] -= amount;
            payable(buyer).transfer(amount);
        } else {
            balances[seller] -= amount;
            payable(seller).transfer(amount);
        }
    }

    function autoReleaseFunds() public {
        require(block.timestamp >= releaseTime, "The release has not been reached");
        require(shipped, "Item has not been shipped");
        require(msg.sender == buyer || msg.sender == seller, "Only the buyer or seller can trigger auto-release");

        balances[buyer] -= amount;
        payable(seller).transfer(amount);
    }
}