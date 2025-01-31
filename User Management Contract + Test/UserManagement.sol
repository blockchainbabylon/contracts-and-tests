//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract UserManagement {
    struct User {
        string name;
        uint256 balance;
    }

    address public owner;
    mapping(address => User) public users;
    uint256 public userCount;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry, you are not the owner");
        _;
    }

    function addUser(address _user, string memory _name, uint256 _balance) public onlyOwner {
        users[_user] = User(_name, _balance);
        userCount++;
    }

    function updateUserBalance(address _user, uint256 _newBalance) public onlyOwner {
        users[_user].balance = _newBalance;
    }

    function getUserInfo(address _user) public view returns (string memory, uint256) {
        User memory user = users[_user];
        return (user.name, user.balance);
    }

    function getTotalUsers() public view returns (uint256) {
        return userCount;
    }
}