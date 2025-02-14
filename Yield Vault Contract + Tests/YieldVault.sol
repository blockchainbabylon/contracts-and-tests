//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract YieldVault {
    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    mapping(address => Deposit) public deposits;
    address public owner;
    uint256 public yieldRate = 5;
    uint256 public lockTime = 7 days;

    event Deposited(address indexed user, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 amount, uint256 yieldEarned);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "Must deposit ETH");
        require(deposits[msg.sender].amount == 0, "Already deposited");

        deposits[msg.sender] = Deposit({
            amount: msg.value,
            unlockTime: block.timestamp + lockTime,
            claimed: false
        });

        emit Deposited(msg.sender, msg.value, block.timestamp + lockTime);
    }

    function withdraw() external {
        Deposit storage userDeposit = deposits[msg.sender];
        require(userDeposit.amount > 0, "No deposit");
        require(block.timestamp >= userDeposit.unlockTime, "Funds are locked");
        require(!userDeposit.claimed, "Already withdrawn");

        uint256 yieldEarned = (userDeposit.amount * yieldRate) / 100;
        uint256 totalPayout = userDeposit.amount + yieldEarned;

        require(address(this).balance >= totalPayout, "Insufficient contract balance");

        userDeposit.claimed = true;
        payable(msg.sender).transfer(totalPayout);

        emit Withdrawn(msg.sender, userDeposit.amount, yieldEarned);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
