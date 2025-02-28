//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../DeFiStaking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeFiStakingTest is Test {
    DeFiStaking staking;
    ERC20 stakingToken;
    ERC20 rewardToken;
    address owner = address(0x123);
    address staker1 = address(0x456);
    address staker2 = address(0x789);
    uint256 rewardRate = 1 ether;

    function setUp() public {
        stakingToken = new ERC20("Staking Token", "STK");
        rewardToken = new ERC20("Reward Token", "RWD");
        staking = new DeFiStaking(stakingToken, rewardToken, rewardRate);

        stakingToken.mint(owner, 1000 ether);
        rewardToken.mint(owner, 1000 ether);

        stakingToken.transfer(staker1, 100 ether);
        stakingToken.transfer(staker2, 100 ether);
    }

    function testStake() public {
        vm.prank(staker1);
        stakingToken.approve(address(staking), 50 ether);
        staking.stake(50 ether);

        assertEq(stakingToken.balanceOf(staker1), 50 ether);
        assertEq(staking.totalStaked(), 50 ether);
        assertEq(staking.stakes(staker1).amount, 50 ether);
    }

    function testWithdraw() public {
        vm.prank(staker1);
        stakingToken.approve(address(staking), 50 ether);
        staking.stake(50 ether);

        vm.prank(staker1);
        staking.withdraw(20 ether);

        assertEq(stakingToken.balanceOf(staker1), 70 ether);
        assertEq(staking.totalStaked(), 30 ether);
        assertEq(staking.stakes(staker1).amount, 30 ether);
    }

    function testClaimReward() public {
        vm.prank(staker1);
        stakingToken.approve(address(staking), 50 ether);
        staking.stake(50 ether);

        vm.roll(block.number + 10);

        vm.prank(staker1);
        staking.claimRewards();

        assertEq(rewardToken.balanceOf(staker1), 10 ether);
    }

    function testSetRewardRate() public {
        vm.prank(owner);
        staking.setRewardRate(2 ether);

        assertEq(staking.rewardRate(), 2 ether);
    }


}