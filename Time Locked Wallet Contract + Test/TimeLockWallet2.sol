//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract TimeLockWallet2 {
    address public owner;
    uint256 public unlockTime;
    uint256 public balance;
    bool public ownerApproval;

    constructor(uint256 _unlockTime) {
        owner = msg.sender;
        unlockTime = _unlockTime + block.timestamp;
    }

    modifier pastUnlockTime() {
        require(block.timestamp >= unlockTime, "You have to wait until funds are allowed to be unlocked");
        _;
    }

    function deposit() public payable {
        require(msg.value > 0, "Need to deposit more than zero");
        balance += msg.value;
    }

    function approveWithdrawalsByOwner() public {
        require(msg.sender == owner, "Sorry, you are not the owner");
        ownerApproval = true;
    }

    function withdraw(uint256 amount) public pastUnlockTime returns(string memory) {
        require(ownerApproval, "Owner has not approved withdrawals");
        require(address(this).balance > 0, "No funds held on the contract");

        balance -= amount;
        ownerApproval = false;

        payable(msg.sender).transfer(amount);
        return "Withdrawal successful";
    }

    function getBalance() public view returns(uint256) {
        return balance;
    }

    function getUnlockTime() public view returns(uint256) {
        if (block.timestamp >= unlockTime) {
            return 0; //already unlocked
        }
        return unlockTime - block.timestamp;
    }
}
