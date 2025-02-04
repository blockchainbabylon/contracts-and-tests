//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Voting2 {
    enum VoteOption { None, Yes, No }

    struct Voter {
        bool hasVoted;
        VoteOption vote;
        uint256 timestamp;
    }

    mapping(address => Voter) public voters;
    uint256 public yesCount;
    uint256 public noCount;
    bytes32 public votingSessionId;

    event Voted(address indexed voter, VoteOption vote, uint256 timestamp);

    function vote(bool _support) external {
        require(!voters[msg.sender].hasVoted, "You have already voted");

        VoteOption selectedVote = _support ? VoteOption.Yes : VoteOption.No;

        voters[msg.sender] = Voter(true, selectedVote, block.timestamp);

        if (_support) {
            yesCount++;
        } else {
            noCount++;
        }

        emit Voted(msg.sender, selectedVote, block.timestamp);
    }

    function getVoteDetails(address _voter) external view returns(VoteOption, uint256) {
        Voter memory voter = voters[_voter];
        return (voter.vote, voter.timestamp);
    }

    function getVotingResult() external view returns(uint256, uint256) {
        return (yesCount, noCount);
    }
}