//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract TimeLockedWallet {
    address public owner;
    uint256 public unlockTime;

    constructor(uint256 _unlockTime) {
        owner = msg.sender;
        unlockTime = _unlockTime + block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry, you are not the owner");
        _;
    }

    function deposit() public payable {
        require(msg.value > 0, "You have to deposit more than zero");
    }

    function withdrawal(uint256 amount) public onlyOwner {
        require(block.timestamp > unlockTime, "Sorry, your funds are still locked");
        payable(msg.sender).transfer(amount);
    }

    function getTimeLeft() public view returns (uint256) {
    return unlockTime > block.timestamp ? unlockTime - block.timestamp : 0;
    }
}