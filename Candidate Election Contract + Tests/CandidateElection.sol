//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Election {
    struct Candidate {
        string name;
        uint256 votes;
    }

    bool public electionEnded;
    address public manager;
    uint256 public candidateCount;

    mapping(address => bool) public hasVoted;
    mapping(uint256 => Candidate) public candidates;
    mapping(string => bool) private alreadyAdded;

    constructor() {
        manager = msg.sender;
    }

    function addCandidate(string memory name) public {
        require(!electionEnded, "Sorry, election ended");
        require(!alreadyAdded[name], "Candidate already added");

        alreadyAdded[name] = true;
        candidateCount++;
        candidates[candidateCount] = Candidate(name, 0);
    }

    function vote(uint256 _candidateId) public {
        require(!hasVoted[msg.sender], "You have already voted");

        hasVoted[msg.sender] = true;
        candidates[_candidateId].votes++;
    }

    function endElection() public {
        require(msg.sender == manager, "Sorry, you are not the manager");
        electionEnded = true;

        uint256 winningVoteCount = 0;
        uint256 winningCandidateId;

        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].votes > winningVoteCount) {
                winningVoteCount = candidates[i].votes;
                winningCandidateId = i;
            } 
        }
    }
}