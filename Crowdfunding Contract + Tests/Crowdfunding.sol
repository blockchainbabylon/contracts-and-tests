//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Crowdfunding {
    struct Project {
        address creator;
        uint256 goal;
        uint256 raisedAmount;
        uint256 deadline;
        bool finalized;
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    uint256 public projectCount;

    event ProjectCreated(uint256 projectId, address creator, uint256 goal, uint256 deadline);
    event ContributionReceived(uint256 projectId, address contributor, uint256 amount);
    event ProjectFinalized(uint256 projectId, bool success);
    event RefundIssued(uint256 projectId, address contributor, uint256 amount);

    function createProject(uint256 goal, uint256 durationInDays) external returns(uint256) {
        require(goal > 0, "Goal must be greater than zero");
        require(durationInDays > 0, "Duration must be greater than zero");

        projectCount++;
        uint256 projectId = projectCount;

        projects[projectId] = Project({
            creator: msg.sender,
            goal: goal,
            raisedAmount: 0,
            deadline: block.timestamp + (durationInDays * 1 days),
            finalized: false
        });

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

    function finalizeProject(uint256 projectId) external {
        Project storage project = projects[projectId];
        require(block.timestamp >= project.deadline, "Project is still ongoing");
        require(!project.finalized, "Project already finalized");
        require(msg.sender == project.creator, "Only the creator can finalize the project");

        project.finalized = true;

        if (project.raisedAmount >= project.goal) {
            payable(project.creator).transfer(project.raisedAmount);
            emit ProjectFinalized(projectId, true);
        } else {
            emit ProjectFinalized(projectId, false);
        }
    }

    function requestRefund(uint256 projectId) external {
        Project storage project = projects[projectId];
        require(project.finalized, "Project is not finalized");
        require(project.raisedAmount < project.goal, "Project met its goal, no refunds");
        require(contributions[projectId][msg.sender] > 0, "You have not contributed to this project");

        uint256 refundAmount = contributions[projectId][msg.sender];
        contributions[projectId][msg.sender] = 0;

        payable(msg.sender).transfer(refundAmount);
        emit RefundIssued(projectId, msg.sender, refundAmount);
    }

    function getProjectDetails(uint256 projectId) external view returns (
        address creator, uint256 goal, uint256 raisedAmount, uint256 deadline, bool finalized
    ) {
        Project storage project = projects[projectId];
        return (project.creator, project.goal, project.raisedAmount, project.deadline, project.finalized);
    }

    function getContribution(uint256 projectId, address contributor) external view returns(uint256) {
        return contributions[projectId][contributor];
    }
}
