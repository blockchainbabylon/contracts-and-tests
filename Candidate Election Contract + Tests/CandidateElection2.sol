// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract RankedChoiceElection {
    struct Candidate {
        string name;
        uint256 id;
        uint256 voteCount;
        bool eliminated;
    }

    struct Voter {
        bool hasVoted;
        uint256[] rankings;
    }

    address public manager;
    bool public electionActive;
    uint256 public candidateCount;
    mapping(uint256 => Candidate) public candidates;
    mapping(address => Voter) public voters;
    mapping(string => bool) private candidateExists;
    address[] private voterList;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can perform this action");
        _;
    }

    function nominateCandidate(string memory _name) public onlyManager {
        require(!electionActive, "Cannot add candidates during an active election");
        require(!candidateExists[_name], "Candidate already nominated");

        candidateCount++;
        candidates[candidateCount] = Candidate(_name, candidateCount, 0, false);
        candidateExists[_name] = true;
    }

    function startElection() public onlyManager {
        require(candidateCount > 1, "At least two candidates required to start the election");
        electionActive = true;
    }

    function vote(uint256[] memory _rankings) public {
        require(electionActive, "Election is not active");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(_rankings.length == candidateCount, "Must rank all candidates");

        voters[msg.sender] = Voter(true, _rankings);
        voterList.push(msg.sender);
    }

    function countVotes() public onlyManager {
        require(electionActive, "Election is not active");

        while (true) {
            resetVoteCounts();
            tallyFirstChoiceVotes();

            uint256 totalVotes = voterList.length;
            uint256 majorityThreshold = totalVotes / 2;
            (uint256 leadingCandidateId, uint256 leadingVotes, uint256 lowestVotes, uint256 lowestCandidateId) = findVoteStats();

            // If a candidate has a majority, declare them the winner and end the election
            if (leadingVotes > majorityThreshold) {
                electionActive = false;
                break;
            }

            // If a tie between remaining candidates, break and declare tie
            if (isTie(lowestVotes)) {
                electionActive = false;
                break;
            }

            // Eliminate the candidate with the fewest votes and redistribute their votes
            candidates[lowestCandidateId].eliminated = true;
        }
    }

    function resetVoteCounts() private {
        for (uint256 i = 1; i <= candidateCount; i++) {
            candidates[i].voteCount = 0;
        }
    }

    function tallyFirstChoiceVotes() private {
        for (uint256 i = 0; i < voterList.length; i++) {
            address voterAddr = voterList[i];
            uint256 firstChoice = getNextValidCandidate(voters[voterAddr].rankings);
            if (firstChoice != 0) {
                candidates[firstChoice].voteCount++;
            }
        }
    }

    function getNextValidCandidate(uint256[] memory rankings) private view returns (uint256) {
        for (uint256 i = 0; i < rankings.length; i++) {
            if (!candidates[rankings[i]].eliminated) {
                return rankings[i];
            }
        }
        return 0;
    }

    function findVoteStats() private view returns (uint256, uint256, uint256, uint256) {
        uint256 leadingCandidateId = 0;
        uint256 leadingVotes = 0;
        uint256 lowestVotes = type(uint256).max;
        uint256 lowestCandidateId = 0;

        for (uint256 i = 1; i <= candidateCount; i++) {
            if (!candidates[i].eliminated) {
                if (candidates[i].voteCount > leadingVotes) {
                    leadingVotes = candidates[i].voteCount;
                    leadingCandidateId = i;
                }
                if (candidates[i].voteCount < lowestVotes) {
                    lowestVotes = candidates[i].voteCount;
                    lowestCandidateId = i;
                }
            }
        }

        return (leadingCandidateId, leadingVotes, lowestVotes, lowestCandidateId);
    }

    function isTie(uint256 lowestVotes) private view returns (bool) {
        uint256 remainingCandidates = 0;
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (!candidates[i].eliminated && candidates[i].voteCount == lowestVotes) {
                remainingCandidates++;
            }
        }
        return remainingCandidates > 1;
    }
}
