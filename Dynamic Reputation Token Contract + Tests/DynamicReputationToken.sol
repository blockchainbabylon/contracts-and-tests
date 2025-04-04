//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DynamicReputationToken is Ownable {
    mapping(address => uint256) public reputationBalance;
    uint256 public totalReputation;

    IERC20 public rewardToken;
    uint256 public rewardAmountPerHolder;
    bool public goalAchieved = false;

    event ReputationAwarded(address recipient, uint256 amount);
    event CollectiveGoalMet(string goalDescription, uint256 totalRewardAmount);
    event RewardClaimed(address claimer, uint256 rewardAmount);

    address[] private reputationHolders;
    mapping(address => bool) private isReputationHolder;

    constructor(address _rewardTokenAddress) Ownable() {
        rewardToken = IERC20(_rewardTokenAddress);
    }

    function awardReputation(address _recipient, uint256 _amount) public onlyOwner {
        reputationBalance[_recipient] += _amount;
        totalReputation += _amount;
        if (!isReputationHolder[_recipient]) {
            reputationHolders.push(_recipient);
            isReputationHolder[_recipient] = true;
        }
        emit ReputationAwarded(_recipient, _amount);
    }

    function setCollectiveGoalMet(uint256 _totalRewardAmount) public onlyOwner {
        require(!goalAchieved, "Goal has already been marked as achieved");
        require(_totalRewardAmount > 0, "Reward amount must be greater than zero");
        rewardAmountPerHolder = _totalRewardAmount / reputationHolders.length;
        goalAchieved = true;
        emit CollectiveGoalMet("Example Collective Goal", _totalRewardAmount);
    }

    function claimReward() public {
        require(goalAchieved, "Collective goal not yet achieved");
        require(reputationBalance[msg.sender] > 0, "Must hold reputation tokens to claim");
        require(rewardAmountPerHolder > 0, "Reward amount per holder not yet calculated");

        uint256 reward = rewardAmountPerHolder;
        reputationBalance[msg.sender] = 0;

        bool success = rewardToken.transfer(msg.sender, reward);
        require(success, "Reward token transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }

    function getReputationHolders() public view returns (address[] memory) {
        return reputationHolders;
    }

    mapping(address => bool) public hasParticipatedInEvent;

    function markParticipation(address _user) public onlyOwner {
        hasParticipatedInEvent[_user] = true;
    }

    function hasAccessToExclusiveFeature(address _user) public view returns (bool) {
        uint256 participationThreshold = 5;
        uint256 participants = 0;
        for (address holder : reputationHolders) {
            if (hasParticipatedInEvent[holder]) {
                participants++;
            }
        }
        return reputationBalance[_user] > 0 && participants >= participationThreshold;
    }
}
