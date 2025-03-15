//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/ComplexDAO.sol";

contract DeFiDAOTest is Test {
    DeFiDAO dao;
    address admin = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);

    function setUp() public {
        vm.prank(admin);
        dao = new DeFiDAO();
    }

    function testMint() public {
        vm.prank(admin);
        dao.mint(user1, 1000 ether);

        assertEq(dao.balances(user1), 1000 ether);
    }

    function testTransfer() public {
        vm.prank(admin);
        dao.mint(user1, 1000 ether);

        vm.prank(user1);
        dao.transfer(user2, 500 ether);

        assertEq(dao.balances(user1), 500 ether);
        assertEq(dao.balances(user2), 500 ether);
    }

    function testStake() public {
        vm.prank(admin);
        dao.mint(user1, 1000 ether);

        vm.prank(user1);
        dao.stake(500 ether);

        assertEq(dao.balances(user1), 500 ether);
        assertEq(dao.stakedBalance(user1), 500 ether);
    }

    function testUnstake() public {
        vm.prank(admin);
        dao.mint(user1, 1000 ether);

        vm.prank(user1);
        dao.stake(500 ether);

        vm.warp(block.timestamp + 7 days);

        vm.prank(user1);
        dao.unstake(500 ether);

        assertEq(dao.balances(user1), 525 ether);
        assertEq(dao.stakedBalances(user1), 0);
    }

    function testCreateProposal() public {
        vm.prank(admin);
        dao.mint(user1, 1000 ether);

        vm.prank(user1);
        dao.stake(500 ether);

        vm.prank(user1);
        uint256 proposalId = dao.createProposal("Increase reward rate", 10);

        (uint256 id, address proposer, string memory descripition, , , , , , ) = dao.proposals(proposalId);
        assertEq(id, proposalId);
        assertEq(proposer, user1);
        assertEq(description, "Increase reward rate");
    }

    function testVote() public {
        vm.prank(admin);
        dao.mint(user1, 1000 ether);
        dao.mint(user2, 1000 ether);

        vm.prank(user1);
        dao.stake(500 ether);

        vm.prank(user2);
        dao.stake(500 ether);

        vm.prank(user1);
        uint256 proposalId = dao.createProposal("Increase reward rate", 10);

        vm.prank(user1);
        dao.vote(proposalId, true);

        vm.prank(user2);
        dao.vote(proposalId, false);

        (, , , uint256 votesFor, uint256 votesAgainst, , , , ) = dao.proposals(proposalId);
        assertEq(votesFor, 500 ether);
        assertEq(votesAgainst, 500 ether);
    }

    function testExecuteProposal() public {
        vm.prank(admin);
        dao.mint(user1, 1000 ether);
        dao.mint(user2, 1000 ether);

        vm.prank(user1);
        dao.stake(500 ether);

        vm.prank(user2);
        dao.stake(500 ether);

        vm.prank(user1);
        uint256 proposalId = dao.createProposal("Increase reward rate", 10);

        vm.prank(user1);
        dao.vote(proposalId, true);

        vm.prank(user2);
        dao.vote(proposalId, false);

        vm.warp(block.timestamp + 3 days);

        vm.prank(user1);
        dao.executeProposal(proposalId);

        (, , , , , , , bool executed, ) = dao.proposals(proposalId);
        assertTrue(executed);
        assertEq(dao.rewardRate(), 10);
    }

    function testWithdrawTreasury() public {
        vm.prank(admin);
        dao.mint(user1, 1000 ether);

        vm.prank(user1);
        dao.stake(500 ether);

        vm.warp(block.timestamp + 7 days);

        vm.prank(user1);
        dao.unstake(500 ether);

        uint256 treasuryBalance = dao.treasuryBalance();

        vm.prank(admin);
        dao.withdrawTreasury(treasuryBalance, admin);

        assertEq(dao.treasuryBalance(), 0);
    }
}
