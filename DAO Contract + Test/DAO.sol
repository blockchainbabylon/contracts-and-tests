//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract SimpleDAO {
    address public owner;
    uint256 public proposalCount;
    uint256 public quorum;

    enum VoteOption { Pending, Yes, No }
    enum ProposalStatus { Pending, Active, Executed, Failed }

    struct Proposal {
        address proposer;
        string description;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 endTime;
        ProposalStatus status;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => VoteOption)) public votes;

    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event Voted(uint256 proposalId, address voter, VoteOption voteOption);
    event ProposalExecuted(uint256 proposalId, bool passed);

    constructor(uint256 _quorum) {
        owner = msg.sender;
        quorum = _quorum;
        proposalCount = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier onlyActiveProposal(uint256 proposalId) {
        require(proposals[proposalId].status == ProposalStatus.Active, "Proposal not active");
        _;
    }

    modifier hasVoted(uint256 proposalId) {
        require(votes[proposalId][msg.sender] == VoteOption.Pending, "Already voted");
        _;
    }

    function createProposal(string memory description) external {
        proposalCount++;
        uint256 proposalId = proposalCount;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: description,
            voteCountYes: 0,
            voteCountNo: 0,
            endTime: block.timestamp + 1 days,
            status: ProposalStatus.Active
        });

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    function vote(uint256 proposalId, VoteOption voteOption) external onlyActiveProposal(proposalId) hasVoted(proposalId) {
        require(block.timestamp < proposals[proposalId].endTime, "Voting period has ended");

        votes[proposalId][msg.sender] = voteOption;

        if (voteOption == VoteOption.Yes) {
            proposals[proposalId].voteCountYes++;
        } else if (voteOption == VoteOption.No) {
            proposals[proposalId].voteCountNo++;
        }

        emit Voted(proposalId, msg.sender, voteOption);
    }

    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active or already executed");
        require(block.timestamp >= proposal.endTime, "Voting period not ended");

        uint256 totalVotes = proposal.voteCountYes + proposal.voteCountNo;
        if (totalVotes >= quorum && proposal.voteCountYes > proposal.voteCountNo) {
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(proposalId, true);
        } else {
            proposal.status = ProposalStatus.Failed;
            emit ProposalExecuted(proposalId, false);
        }
    }
}