//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract VotingContract {
    enum VoteOption { NotVoted, CandidateA, CandidateB }

    struct Voter {
        address voterAddress;
        VoteOption voteStatus;
    }

    mapping(address => Voter) public voters;
    uint256 public totalVotesA;
    uint256 public totalVotesB;
    address public owner;
    bool public votingOpen;

    event VoterRegistered(address voter);
    event Voted(address voter, VoteOption voteOption);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlyWhenVotingOpen() {
        require(votingOpen, "Voting is not open");
        _;
    }

    modifier onlyWhenVotingClosed() {
        require(!votingOpen, "Voting is still open");
        _;
    }

    constructor() {
        owner = msg.sender;
        votingOpen = false;
    }

    function openVoting() public onlyOwner {
        votingOpen = true;
    }

    function closeVoting() public onlyOwner {
        votingOpen = false;
    }

    function registerVoter() public {
        require(voters[msg.sender].voterAddress == address(0), "Already registered");
        voters[msg.sender] = Voter(msg.sender, VoteOption.NotVoted);
        emit VoterRegistered(msg.sender);
    }

    function vote(VoteOption _voteOption) public {
        require(voters[msg.sender].voterAddress != address(0), "You are not registered");
        require(voters[msg.sender].voteStatus == VoteOption.NotVoted, "You have already voted");
        require(_voteOption == VoteOption.CandidateA || _voteOption == VoteOption.CandidateB, "Invalid vote option");

        voters[msg.sender].voteStatus = _voteOption;

        if (_voteOption == VoteOption.CandidateA) {
            totalVotesA++;
        } else if (_voteOption == VoteOption.CandidateB) {
            totalVotesB++;
        }

        emit Voted(msg.sender, _voteOption);
    }

    function getTotalVotes() public view returns (uint256 votesA, uint256 votesB) {
        return (totalVotesA, totalVotesB);
    }

    function getVotingStatus() public view returns (VoteOption) {
        return voters[msg.sender].voteStatus;
    }
}