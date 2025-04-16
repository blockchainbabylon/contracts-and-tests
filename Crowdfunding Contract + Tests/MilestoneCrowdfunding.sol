// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract MilestoneCrowdfunding {
    struct Milestone {
        string description;
        uint256 amount;
        bool completed;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    struct Project {
        address creator;
        uint256 goal;
        uint256 raisedAmount;
        uint256 deadline;
        bool finalized;
        uint256 milestoneCount;
        mapping(uint256 => Milestone) milestones;
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    uint256 public projectCount;

    event ProjectCreated(uint256 projectId, address creator, uint256 goal, uint256 deadline);
    event ContributionReceived(uint256 projectId, address contributor, uint256 amount);
    event MilestoneAdded(uint256 projectId, uint256 milestoneId, string description, uint256 amount);
    event MilestoneApproved(uint256 projectId, uint256 milestoneId, address approver);
    event MilestoneCompleted(uint256 projectId, uint256 milestoneId);
    event ProjectFinalized(uint256 projectId, bool success);

    modifier onlyCreator(uint256 projectId) {
        require(msg.sender == projects[projectId].creator, "Only the creator can perform this action");
        _;
    }

    function createProject(uint256 goal, uint256 durationInDays) external returns (uint256) {
        require(goal > 0, "Goal must be greater than zero");
        require(durationInDays > 0, "Duration must be greater than zero");

        projectCount++;
        uint256 projectId = projectCount;

        projects[projectId].creator = msg.sender;
        projects[projectId].goal = goal;
        projects[projectId].deadline = block.timestamp + (durationInDays * 1 days);

        emit ProjectCreated(projectId, msg.sender, goal, projects[projectId].deadline);
        return projectId;
    }

    function contribute(uint256 projectId) external payable {
        Project storage project = projects[projectId];
        require(block.timestamp < project.deadline, "Project deadline has passed");
        require(msg.value > 0, "Contribution must be greater than zero");
        require(!project.finalized, "Project is already finalized");

        project.raisedAmount += msg.value;
        contributions[projectId][msg.sender] += msg.value;

        emit ContributionReceived(projectId, msg.sender, msg.value);
    }

    function addMilestone(
        uint256 projectId,
        string memory description,
        uint256 amount
    ) external onlyCreator(projectId) {
        Project storage project = projects[projectId];
        require(!project.finalized, "Project is already finalized");
        require(project.raisedAmount + amount <= project.goal, "Milestone exceeds project goal");

        project.milestoneCount++;
        uint256 milestoneId = project.milestoneCount;

        Milestone storage milestone = project.milestones[milestoneId];
        milestone.description = description;
        milestone.amount = amount;

        emit MilestoneAdded(projectId, milestoneId, description, amount);
    }

    function approveMilestone(uint256 projectId, uint256 milestoneId) external {
        Project storage project = projects[projectId];
        Milestone storage milestone = project.milestones[milestoneId];

        require(contributions[projectId][msg.sender] > 0, "Only contributors can approve milestones");
        require(!milestone.completed, "Milestone already completed");
        require(!milestone.approvals[msg.sender], "You have already approved this milestone");

        milestone.approvals[msg.sender] = true;
        milestone.approvalCount++;

        emit MilestoneApproved(projectId, milestoneId, msg.sender);

        if (milestone.approvalCount > project.raisedAmount / 2) {
            milestone.completed = true;
            payable(project.creator).transfer(milestone.amount);
            emit MilestoneCompleted(projectId, milestoneId);
        }
    }

    function finalizeProject(uint256 projectId) external onlyCreator(projectId) {
        Project storage project = projects[projectId];
        require(block.timestamp >= project.deadline, "Project is still ongoing");
        require(!project.finalized, "Project already finalized");

        project.finalized = true;

        if (project.raisedAmount >= project.goal) {
            emit ProjectFinalized(projectId, true);
        } else {
            emit ProjectFinalized(projectId, false);
        }
    }

    function getProjectDetails(uint256 projectId)
        external
        view
        returns (
            address creator,
            uint256 goal,
            uint256 raisedAmount,
            uint256 deadline,
            bool finalized,
            uint256 milestoneCount
        )
    {
        Project storage project = projects[projectId];
        return (
            project.creator,
            project.goal,
            project.raisedAmount,
            project.deadline,
            project.finalized,
            project.milestoneCount
        );
    }

    function getMilestoneDetails(uint256 projectId, uint256 milestoneId)
        external
        view
        returns (
            string memory description,
            uint256 amount,
            bool completed,
            uint256 approvalCount
        )
    {
        Milestone storage milestone = projects[projectId].milestones[milestoneId];
        return (milestone.description, milestone.amount, milestone.completed, milestone.approvalCount);
    }
}