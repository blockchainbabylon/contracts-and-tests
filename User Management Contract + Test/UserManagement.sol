//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract UserManagement {
    struct User {
        string name;
        uint256 balance;
    }

    address public owner;
    mapping(address => User) public users; //assigns address to instance of user struct
    uint256 public userCount;

    constructor() {
        owner = msg.sender; //assign owner as contract deployer
    }

    //give only the owner access to certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry, you are not the owner"); 
        _;
    }

    //allows only the owner to add new instance of User struct
    function addUser(address _user, string memory _name, uint256 _balance) public onlyOwner {
        users[_user] = User(_name, _balance);
        userCount++;
    }

    //allows only the owner to change the balance of a specific user that was already added
    function updateUserBalance(address _user, uint256 _newBalance) public onlyOwner {
        users[_user].balance = _newBalance;
    }

    //allows anyone to get info about users added
    function getUserInfo(address _user) public view returns (string memory, uint256) {
        User memory user = users[_user];
        return (user.name, user.balance);
    }

    //allows anyone to return how many users were added in total
    function getTotalUsers() public view returns (uint256) {
        return userCount;
    }
}