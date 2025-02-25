//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract TimeLockedWallet {
    mapping(address => uint256) public lockTime;
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit(uint256 _lockTime) public payable {
        require(msg.value > 0, "Have to deposit more than zero");

        balances[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + _lockTime;

        emit Deposited(msg.sender, msg.value);

    }

    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Has to be more than zero");
        require(block.timestamp > lockTime[msg.sender], "Has not been enough time");
        require(_amount <= balances[msg.sender], "Not enough balance");
        balances[msg.sender] -= _amount;
        
        payable(msg.sender).transfer(_amount);

        emit Withdraw(msg.sender, _amount);
    }

    function checkBalance(address _user) public view returns(uint256) {
        return balances[_user];
    }
    
    function checkLockTime(address _user) public view returns(uint256) {
        return lockTime[_user];
    }

}
