//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "std-forge/Test.sol";
import "../src/Voting2.sol";

contract Voting2Test is Test {
    Voting2 voting;
    address voter1 = address(0x123);
    address voter2 = address(0x456);

    function setUp() public {
        voting = new Voting2();
    }

    function testVoteYes() public {
        vm.prank(voter1);
        voting.vote(true);

        (bool hasVoted, Voting2.VoteOption vote, uint256 timestamp) = voting.voters(voter1);
        assertTrue(hasVoted);
        assertEq(uint256(vote), uint256(Voting2.VoteOption.Yes));
        assertGt(timestamp, 0);
        assertEq(voting.yesCount(), 1);
        assertEq(voting.noCount(), 0);
    }

    function testVoteNo() public {
        vm.prank(voter1);
        voting.vote(false);

        (bool hasVoted, Voting2.VoteOption vote, uint256 timestamp) = voting.voters(voter1);
        assertTrue(hasVoted);
        assertEq(uint256(vote), uint256(Voting2.VoteOption.No));
        assertGt(timestamp, 0);
        assertEq(voting.yesCount(), 0);
        assertEq(voting.noCount(), 1);
    }

    function TestVoteTwice() public {
        vm.prank(voter1);
        voting.vote(true);

        vm.prank(voter1);
        vm.expectRevert("You have already voted");
        voting.vote(false);
    }

    function testGetVoteDetails() public {
        vm.prank(voter1);
        voting.vote(true);

        (Voting2.VoteOption vote, uint256 timestamp) = voting.getVoteDetails(voter1);
        assertEq(uint256(vote), uint256(Voting2.VoteOption.Yes));
        assertGt(timestamp, 0);
    }

    function testGetVoteDetailsNotVoted() public {
        (Voting2.VoteOption vote, uint256 timestamp) = voting.getVoteDetails(voter2);
        assertEq(uint256(vote), uint256(Voting2.VoteOption.None));
        assertEq(timestamp, 0);
    }
}