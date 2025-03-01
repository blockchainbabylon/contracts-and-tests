//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/DeFiStaking.sol";

contract DeFiStakingTokenTest is Test {
    DeFiStakingToken stakingToken;
    address owner = address(0x123);
    address staker1 = address(0x456);
    address staker2 = address(0x789);

    function setUp() public {
        vm.prank(owner);
        stakingToken = new DeFiStakingToken();

        vm.prank(owner);
        stakingToken.transfer(staker1, 100 ether);
        vm.prank(owner);
        stakingToken.transfer(staker2, 100 ether);
    }

    function testStake() public {
        vm.prank(staker1);
        stakingToken.stake(50 ether);

        assertEq(stakingToken.balanceOf(staker1), 50 ether);
        assertEq(stakingToken.stakes(staker1).amount, 50 ether);
    }

    function testUnstake() public {
        vm.prank(staker1);
        stakingToken.stake(50 ether);

        vm.warp(block.timestamp + 30 days);

        vm.prank(staker1);
        stakingToken.unstake();

        assertEq(stakingToken.balanceOf(staker1), 100 ether);
        assertEq(stakingToken.stakes(staker1).amount, 0);
    }

    function testClaimRewards() public {
        vm.prank(staker1);
        stakingToken.approve(address(stakingToken), 50 ether);
        stakingToken.stake(50 ether);

        vm.warp(block.timestamp + 365 days);

        vm.prank(staker1);
        stakingToken.claimRewards();

        uint256 expectedReward = (50 ether * 5 * 365 days) / (365 days * 100);
        assertEq(stakingToken.balanceOf(staker1), 50 ether + expectedReward);
        assertEq(stakingToken.rewards(staker1), 0);
    }

    function testSetRewardRate() public {
        vm.prank(owner);
        stakingToken.setRewardRate(10);

        assertEq(stakingToken.rewardRate(), 10);
    }

    function testSetRewardRateNotOwner() public {
        vm.prank(staker1);
        vm.expectRevert("Not contract owner");
        stakingToken.setRewardRate(10);
    }
}