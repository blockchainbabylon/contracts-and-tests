//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Voting3Test is Test {
    Voting3 voting;
    address voter1 = address(0x123);
    address voter2 = address(0x456);

    function setUp() public {
        voting = new Voting3();
    }

    function testRegisterVote() public {
        vm.prank(voter1); //act as voter1
        voting.registerVote(); //call registerVoting function as voter1

        (address voterAddress, Voting3.VoteOption voteStatus) = voting.voters(voter1); //set voter1 struct 
        assertEq(voterAddress, voter1); //checks voterAddress is voter1
        assertEq(uint256(voteStatus), uint256(Voting3.VoteOption.NotVoted)); //user has not yet voted so checks if enum is at 0
    }

    function testVoteCandidateA() public {
        vm.prank(voter1); //act as voter1
        voting.registerVoter(); //call registerVoter function as voter1

        vm.prank(voter1); //act as voter1
        voting.vote(Voting3.VoteOption.CandidateA); //vote for Candidate A as voter1

        (address voteAddress, Voter3.VoteOption voteStatus) = voting.voters(voter1); //set struct before checking
        assertEq(voterAddress, voter1); //checks that voter1 is assigned as voterAddress in struct
        assertEq(uint256(voteStatus), uint256(Voting3.VoteOption.CandidateA)); //checks voter1 voted for candidate A

        (uint256 votesA, uint256 votesB) = voting.getTotalVotes();
        assertEq(votesA, 1); //checks votes for both candidates
        assertEq(votesB, 0);
    }

    function testVoteCandidateB() public {
        vm.prank(voter1);
        voting.registerVoter();

        vm.prank(voter1);
        voting.vote(Voting3.VoteOption.CandidateB);

        (address voterAddress, Voting3.VoteOption voteStatus) = voting.voters(voter1);
        assertEq(voterAddress, voter1);
        assertEq(uint256(voteStatus), uint256(Voting3.VoteOption.CandidateB));

        (uint256 votesA, uint256 votesB) = voting.getTotalVotes();
        assertEq(votesA, 0);
        assertEq(votesB, 1);
    }

    function testVoteNotRegistered() public {
        vm.prank(voter1);
        vm.expectRevert("You are not registered"); //expect revert when trying to vote and not registered
        voting.vote(Voting3.VoteOption.CandidateA);
    }

    function testVoteTwice() public {
        vm.prank(voter1);
        voting.registerVoter();

        vm.prank(voter1);
        voting.vote(Voting3.VoteOption.CandidateA);

        vm.prank(voter1);
        vm.expectRevert("You have already voted"); //expects revert when user tries to vote more than 1 time
        voting.vote(Voting3.VoteOption.CandidateB);
    }

    function testInvalidVoteOption() public {
        vm.prank(voter1);
        voting.registerVoter();
        
        vm.prank(voter1);
        vm.expectRevert("Invalid vote option"); //expect revert when voting for a candidate not in enum
        voting.vote(Voting3.VoteOption(3));
    }

    function testGetVotingStatus() public {
        vm.prank(voter1);
        voting.registerVoter();

        vm.prank(voter1);
        voting.vote(Voting3.VoteOption.CandidateA); //have user vote for candidate A

        vm.prank(voter1);
        Voting3.VoteOption voteStatus = voting.getVotingStatus(); //returns users current voteStatus
        assertEq(uint256(voteStatus), uint256(Voting3.VoteOption.CandidateA)); //voted for candidate A so voteStatus should be equal
    }
}