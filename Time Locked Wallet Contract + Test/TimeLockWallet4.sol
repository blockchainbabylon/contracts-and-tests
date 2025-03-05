//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// /\_/\  
//( o.o ) 
// > ^ <

contract TimeLockWallet {
    mapping(address => bool) public hasDeposited;
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public unlockTimes;

    event Deposited(address user, uint256 withdrawalTime, uint256 amount);
    event Withdraw(address user, uint256 amount);

    function deposit(uint256 _withdrawalTime) public payable {
        require(!hasDeposited[msg.sender], "Sorry, you have already deposited");
        require(msg.value > 0, "You must deposit more than zero");
        require(_withdrawalTime > 0, "Withdrawal time must be in the future");

        unlockTimes[msg.sender] = _withdrawalTime + block.timestamp;
        deposited[msg.sender] = msg.value;
        hasDeposited[msg.sender] = true;

        emit Deposited(msg.sender, unlockTimes[msg.sender], msg.value);
    }

    function withdrawal() public {
        require(deposited[msg.sender] > 0, "You have nothing to withdraw");
        require(block.timestamp >= unlockTimes[msg.sender], "Funds are still locked");

        uint256 _amount = deposited[msg.sender];
        deposited[msg.sender] = 0;
        unlockTimes[msg.sender] = 0;
        hasDeposited[msg.sender] = false;

        payable(msg.sender).transfer(_amount);

        emit Withdraw(msg.sender, _amount);
    }
}
