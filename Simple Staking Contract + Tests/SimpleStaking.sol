//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleStaking {
    IERC20 public stakingToken;
    uint256 public rewardRate;
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) public lastUpdateTime;

    constructor(IERC20 _stakingToken, uint256 _rewardRate) {
        stakingToken = _stakingToken;
        rewardRate = _rewardRate;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake zero tokens");
        updateRewards(msg.sender);
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0 && amount <= stakedBalance[sg.sender], "Invalid amount");
        updateRewards(msg.sender);
        stakedBalance[msg.sender] -= amount;
        stakingToken.trasfer(msg.sender, amount);
    }

    function claimRewards() external {
        updateRewards(msg.sender);
        uint256 rewards = rewardDebt[msg.sender];
        require(rewards > 0, "No rewards available");
        rewardDebt[msg.sender] = 0;
        stakingToken.transfer(msg.sender, rewards);
    }

    function updateRewards(address user) internal {
        if (lastUpdateTime[user] > 0) {
            uint256 duration = block.timestamp - lastUpdateTime[user];
            rewardDebt[user] += (stakedBalance[user] * rewardRate * duration) / 1e18;
        }
        lastUpdateTime[user] = block.timestamp;
    }
}
