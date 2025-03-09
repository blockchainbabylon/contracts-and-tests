//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/CandidateElection.sol";

contract CandidateElectionTest is Test {
    election electionContract;
    address manager = address(0x123);
    address voter1 = address(0x456);
    address voter2 = address(0x789);

    function setUp() public {
        vm.prank(manager);
        electionContract = new election();
    }

    function testAddCandidate() public {
        vm.prank(manager);
        electionContract.addCandidate("Richard");

        (string memory name, uint256 votes) = electionContract.candidates(1);
        assertEq(name, "Richard");
        assertEq(votes, 0);
    }

    function testAddCandidateElectionEnded() public {
        vm.prank(manager);
        electionContract.endElection;

        vm.prank(manager);
        vm.expectRevert("Sorry, election ended");
        electionContract.addCandidate("Richard")
    }

    function testVote() public {
        vm.prank(manager);
        electionContract.addCandidate("Richard");

        vm.prank(voter1);
        electionContract.vote(1);

        (, uint256 votes) = electionContract.candidates(1);
        assertEq(votes, 1);
        assertTrue(electionContract.hasVoted(voter1));
    }

    function testVoteTwice() public {
        vm.prank(manager);
        electionContract.addCandidate("Richard");

        vm.prank(voter1);
        electionContract.vote(1);

        vm.prank(voter1);
        vm.expectRevert("You have already voted")
        electionContract.vote(1);
    }

    function testEndElection() public {
        vm.prank(manager);
        electionContract.addCandidate("Richard");
        electionContract.addCandidate("Goodhue");

        vm.prank(voter1);
        electionContract.vote(1);

        vm.prank(voter2);
        electionContract.vote(2);

        vm.prank(manager);
        electionContract.endElection();

        assertTrue(electionContract.electionEnded());
    }

    function testEndElectionNotManager() public {
        vm.prank(manager);
        electionContract.addCandidate("Richard");

        vm.prank(voter1);
        vm.expectRevert("Sorry, you are not the manager");
        electionContract.endElection();
    }
}