//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract TimeLockedLiquidityPool {
    struct Deposit {
        uint256 amount;
        uint256 depositTime;
    }

    mapping(address => Deposit) private deposits;
    uint256 public totalPoolBalance;
    uint256 public constant MIN_LOCK_TIME = 30 days;
    address public owner;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 interest);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        require(deposits[msg.sender].amount == 0, "Existing deposit found");

        deposits[msg.sender] = Deposit(msg.value, block.timestamp);
        totalPoolBalance += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function calculateInterest(uint256 amount, uint256 timeHeld) public view returns(uint256) {
        uint256 baseRate = getCurrentAPY();
        return (amount * baseRate * timeHeld) / (365 days * 100);
    }

    function getCurrentAPY() public view returns(uint256) {
        if (totalPoolBalance < 10 ether) return 5;
        if (totalPoolBalance < 50 ether) return 10;
        return 15;
    }

    function withdraw() external {
        Deposit storage userDeposit = deposits[msg.sender];
        require(userDeposit.amount > 0, "No active deposit");

        uint256 timeHeld = block.timestamp - userDeposit.depositTime;
        require(timeHeld >= MIN_LOCK_TIME, "Funds are still locked");

        uint256 interest = calculateInterest(userDeposit.amount, timeHeld);
        uint256 payout = userDeposit.amount + interest;

        totalPoolBalance -= userDeposit.amount;
        delete deposits[msg.sender];

        payable(msg.sender).transfer(payout);
        emit Withdrawn(msg.sender, userDeposit.amount, interest);
    }

    function emergencyWithdraw() external {
        Deposit storage userDeposit = deposits[msg.sender];
        require(userDeposit.amount > 0, "No active deposit");

        uint256 penalty = (userDeposit.amount * 20) / 100;
        uint256 payout = userDeposit.amount - penalty;

        totalPoolBalance -= userDeposit.amount;
        delete deposits[msg.sender];

        payable(msg.sender).transfer(payout);
        emit Withdrawn(msg.sender, userDeposit.amount, 0);
    }

    function getDepositInfo(address user) external view returns(uint256, uint256) {
        return (deposits[user].amount, deposits[user].depositTime);
    }

    receive() external payable {}
}