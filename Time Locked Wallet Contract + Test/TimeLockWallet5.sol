//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract TimeLockWallet {
    address public beneficiary;
    uint256 public depositedAmount;
    uint256 public unlockTime;

    constructor(uint256 _unlockTime) {
        unlockTime = block.timestamp + _unlockTime;
        beneficiary = msg.sender;
    }

    event Deposit(uint256 amount, address depositer);
    event Withdraw(address from, address to, uint256 amount);

    function deposit() public payable {
        require(msg.value > 0, "Have to deposit more than zero");
        
        depositedAmount += msg.value;

        emit Deposit(msg.value, msg.sender);
    }

    function withdraw(address recipient, uint256 amount) public {
        require(beneficiary == msg.sender, "You are not the beneficiary");
        require(block.timestamp >= unlockTime, "It is not passed the unlockTime");
        require(amount > 0, "Cannot transfer 0");
        require(amount <= address(this).balance, "Cannot withdraw more than deposited");
        require(recipient != address(0), "Cannot transfer to zero address");

        depositedAmount -= amount;
        payable(recipient).transfer(amount);

        emit Withdraw(msg.sender, recipient, amount);
    }

    function checkTimeLeft() public view returns(uint256) {
        if (block.timestamp > unlockTime) {
            return 0;
        } else {
            return unlockTime - block.timestamp;
        }
    }
}
