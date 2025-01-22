//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Wallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {}

    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(address(this).balance >= _amount, "Insufficient balance");
        payable(owner).transfer(_amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}