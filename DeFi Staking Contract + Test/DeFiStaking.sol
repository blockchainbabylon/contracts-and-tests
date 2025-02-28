//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract DeFiStakingToken {
    string public name = "DeFi Staking Token";
    string public symbol = "DST";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;
    uint256 public rewardRate = 5; //5% annual reward

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public rewards;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalSupply = 1_000_000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns(bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns(bool) {
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        require(balanceOf[from] >= value, "Insufficient balance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function stake(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Not enough tokens to stake");

        if (stakes[msg.sender].amount > 0) {
            _updateRewards(msg.sender);
        }

        balanceOf[msg.sender] -= amount;
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].startTime = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function unstake() external {
        require(stakes[msg.sender].amount > 0, "No active stake");

        _updateRewards(msg.sender);

        uint256 amount = stakes[msg.sender].amount;
        stakes[msg.sender].amount = 0;

        balanceOf[msg.sender] += amount;

        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external {
        _updateRewards(msg.sender);
        
        require(rewards[msg.sender] > 0, "No rewards available");

        uint256 rewardAmount = rewards[msg.sender];
        rewards[msg.sender] = 0;
        balanceOf[msg.sender] += rewardAmount;
        totalSupply += rewardAmount;

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    function _updateRewards(address user) internal {
        uint256 stakedAmount = stakes[user].amount;
        uint256 stakingTime = block.timestamp - stakes[user].startTime;

        if (stakedAmount > 0 && stakingTime > 0) {
            uint256 reward = (stakedAmount * rewardRate * stakingTime) / (365 days * 100);
            rewards[user] += reward;
            stakes[user].startTime = block.timestamp;
        }
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        require(newRate <= 10, "Reward rate too high");
        rewardRate = newRate;
    }
}