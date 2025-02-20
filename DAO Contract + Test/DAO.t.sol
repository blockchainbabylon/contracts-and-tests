//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/DAO.sol";

contract SimpleDAOTest is Test {
    SimpleDAO dao;
    address owner = address(0x123);
    address voter1 = address(0x456);
    address voter2 = address(0x789);

    function setUp() public {
        vm.prank(owner);
        dao = new SimpleDAO(2);
    }

    function testCreateProposal() public {
        vm.prank(voter1);
        dao.createProposal("Test Proposal");

        (address proposer, string memory description, , , , SimpleDAO.ProposalStatus status) = dao.proposals(1);
        assertEq(proposer, voter1);
        assertEq(description, "Test Proposal");
        assertEq(uint(status), uint(SimpleDAO.ProposalStatus.Active));
    }

    function testVote() public {
        vm.prank(voter1);
        dao.createProposal("Test Proposal");

        vm.prank(voter1);
        dao.vote(1, SimpleDAO.VoteOption.Yes);

        (, , uint256 voteCountYes, uint256 voteCountNo, , ) = dao.proposals(1);
        assertEq(voteCountYes, 1);
        assertEq(voteCountNo, 0);

        vm.prank(voter2);
        dao.vote(1, SimpleDAO.VoteOption.No);

        (, , voteCountYes, voteCountNo, , ) = dao.proposals(1);
        assertEq(voteCountYes, 1);
        assertEq(voteCountNo, 1);
    }

    function testVoteTwice() public {
        vm.prank(voter1);
        dao.createProposal("Test Proposal");

        vm.prank(voter1);
        dao.vote(1, SimpleDAO.VoteOption.Yes);

        vm.prank(voter1);
        vm.expectRevert("Already voted");
        dao.vote(1, SimpleDAO.VoteOption.No);
    }

    function testExecuteProposal() public {
        vm.prank(voter1);
        dao.createProposal("Test Proposal");

        vm.prank(voter1);
        dao.vote(1, SimpleDAO.VoteOption.Yes);

        vm.prank(voter2);
        dao.vote(1, SimpleDAO.VoteOption.Yes);

        vm.warp(block.timestamp + 1 days);

        vm.prank(owner);
        dao.executeProposal(1);

        (, , , , , SimpleDAO.ProposalStatus status) = dao.proposals(1);
        assertEq(uint(status), uint(SimpleDAO.ProposalStatus.Executed));
    }

    function testExecuteProposalFailed() public {
        vm.prank(voter1);
        dao.createProposal("Test Proposal");

        vm.prank(voter1);
        dao.vote(1, SimpleDAO.VoteOption.No);

        vm.prank(voter2);
        dao.vote(1, SimpleDAO.VoteOption.No);

        vm.warp(block.timestamp + 1 days);

        vm.prank(owner);
        dao.executeProposal(1);

        (, , , , , SimpleDAO.ProposalStatus status) = dao.proposals(1);
        assertEq(uint(status), uint(SimpleDAO.ProposalStatus.Failed));
    }
}