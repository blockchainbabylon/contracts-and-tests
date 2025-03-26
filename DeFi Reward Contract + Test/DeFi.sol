//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SimpleDeFi {
    IERC20 public token;

    struct Deposit {
        uint256 amount;
        uint256 lastDepositTime;
        uint256 rewards;
    }

    mapping(address => Deposit) public deposits;

    uint256 public interestRate = 5;
    uint256 public rewardInterval = 365 days;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        token.transferFrom(msg.sender, address(this), amount);
        Deposit storage userDeposit = deposits[msg.sender];

        if (userDeposit.amount > 0) {
            uint256 reward = calculateRewards(msg.sender);
            userDeposit.rewards += reward;
        }

        userDeposit.amount += amount;
        userDeposit.lastDepositTime = block.timestamp;

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        Deposit storage userDeposit = deposits[msg.sender];

        require(userDeposit.amount >= amount, "Insufficient balance to withdraw");

        uint256 reward = calculateRewards(msg.sender);
        userDeposit.rewards += reward;

        userDeposit.amount -= amount;

        token.transfer(msg.sender, amount + userDeposit.rewards);

        userDeposit.rewards = 0;

        emit Withdrawn(msg.sender, amount + userDeposit.rewards);
    }

    function calculateRewards(address user) public view returns(uint256) {
        Deposit storage userDeposit = deposits[user];

        if (block.timestamp < userDeposit.lastDepositTime + rewardInterval) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - userDeposit.lastDepositTime;
        uint256 reward = (userDeposit.amount * interestRate * timeElapsed) / (100 * rewardInterval);

        return reward;
    }

    function totalBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getUserDeposit(address user) external view returns (uint256, uint256) {
        Deposit storage userDeposit = deposits[user];
        uint256 reward = calculateRewards(user);
        return (userDeposit.amount, userDeposit.rewards + reward);
    }
}
