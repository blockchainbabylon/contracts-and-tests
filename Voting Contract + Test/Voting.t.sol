//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "std-forge/Test.sol";
import "../src/Voting.sol";

contract VotingTest is Test {
    Voting voting;
    address owner = address(0x123);
    address voter1 = address(0x456);
    address voter2 = address(0x789);

    function setUp() public {
        vm.prank(owner);
        voting = new Voting();
    }

    function testAddCandidate() public {
        vm.prank(owner);
        voting.addCandidate("Alice");

        (string memory name, uint256 voteCount) = voting.candidates(0);
        assertEq(name, "Alice");
        assertEq(voteCount, 0);
    }

    function testAddCandidateNotOwner() public {
        vm.prank(voter1);
        vm.expectRevert("Only owner can call this function");
        voting.addCandidate("Bob");
    }

    function testVote() public {
        vm.prank(owner);
        voting.addCandidate("Alice");

        vm.prank(voter1);
        voting.vote(0);

        ( , uint256 voteCount) = voting.candidates(0);
        assertEq(voteCount, 1);
        assertTrue(voting.hasVoted(voter1));
    }

    function testVoteTwice() public {
        vm.prank(owner);
        voting.addCandidate("Alice");

        vm.prank(voter1);
        voting.vote(0);

        vm.prank(voter1);
        vm.expectRevert("You have already voted");
        voting.vote(0);
    }

    function testVoteInvalidCandidate() public {
        vm.prank(voter1);
        vm.expectRevert("Invalid candidate index");
        voting.vote(0);
    }
}