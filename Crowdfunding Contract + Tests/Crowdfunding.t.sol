//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding crowdfunding;
    address creator = address(0x123);
    address contributor1 = address(0x456);
    address contributor2 = address(0x789);

    function setUp() public {
        crowdfunding = new Crowdfunding();
    }

    function testCreateProject() public {
        vm.prank(creator);
        uint256 projectId = crowdfunding.createProject(100 ether, 30);

        (address projectCreator, uint256 goal, uint256 raisedAmount, uint256 deadline, bool finalized) = crowdfunding.getProjectDetails(projectId);

        assertEq(projectCreator, creator);
        assertEq(goal, 100 ether);
        assertEq(raisedAmount, 0);
        assertEq(finalized, false);
        assertTrue(deadline > block.timestamp);
    }

    function testContribute() public {
        vm.prank(creator);
        uint256 projectId = crowdfunding.createProject(100 ether, 30);

        vm.prank(contributor1);
        crowdfunding.contribute{value: 10 ether}(projectId);

        (, , uint256 raisedAmount, , ) = crowdfunding.getProjectDetails(projectId);
        assertEq(raisedAmount, 10 ether);
        assertEq(crowdfunding.getContribution(projectId, contributor1), 10 ether);
    }

    function testFinalizeProjectSuccess() public {
        vm.prank(creator);
        uint256 projectId = crowdfunding.createProject(100 ether, 30);

        vm.prank(contributor1);
        crowdfunding.contribute{value: 100 ether}(projectId);

        vm.warp(block.timestamp + 31 days);

        vm.prank(creator);
        crowdfunding.finalizeProject(projectId);

        (, , uint256 raisedAmount, , bool finalized) = crowdfunding.getProjectDetails(projectId);
        assertEq(raisedAmount, 100 ether);
        assertTrue(finalized);
    }

    function testRequestRefund() public {
        vm.prank(creator);
        uint256 projectId = crowdfunding.createProject(100 ether, 30);
        
        vm.prank(contributor1);
        crowdfunding.contribute{value: 50 ether}(projectId);

        vm.warp(block.timestamp + 31 days);

        vm.prank(creator);
        crowdfunding.finalizeProject(projectId);

        vm.prank(contributor1);
        crowdfunding.requestRefund(projectId);

        assertEq(crowdfunding.getContribution(projectId, contributor1), 0);
    }
}