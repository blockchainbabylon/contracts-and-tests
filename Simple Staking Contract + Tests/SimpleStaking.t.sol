//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/SimpleStaking.sol";
import "@openzeppelin/contracts/tokens/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, address initialAccount, uint256 initialBalance)
        ERC20(name, symbol)
    {
        _mint(initialAccount, initialBalance);
    }
}

contract SimpleStakingTest is Test {
    SimpleStaking stakingContract;
    ERC20Mock stakingToken;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);
    uint256 rewardRate = 1e16;

    function setUp() public {
        stakingToken = newERCMock("Staking Token", "STK", owner, 1_000_000 ether);

        vm.prank(owner);
        stakingContract = new SimpleStaking(IERC20(address(stakingToken)), rewardRate);

        stakingToken.transfer(user1, 1_000 ether);
        stakingToken.transfer(user2, 1_000 ether);

        vm.prank(user1);
        stakingToken.approve(address(stakingContract), type(uint256).max);

        vm.prank(user2);
        stakingToken.approve(address(stakingContract), type(uint256).max);
    }

    function testStakeTokens() public {
        vm.prank(user1);
        stakingContract.stake(100 ether);

        assertEq(stakingContract.stakedBalance(user1), 100 ether);
        assertEq(stakingToken.balanceOf(user1), 900 ether);
    }

    function testWithdrawTokens() public {
        vm.prank(user1);
        stakingContract.stake(100 ether);

        vm.prank(user1);
        stakingContract.withdraw(50 ether);

        assertEq(stakingContract.stakedBalance(user1), 50 ether);
        assertEq(stakingToken.balanceOf(user1), 950 ether);
    }

    function testCannotWithdrawMoreThanStaked() public {
        vm.prank(user1);
        stakingContract.stake(100 ether);

        vm.prank(user1);
        vm.expectRevert("Invalid amount");
        stakingContract.withdraw(200 ether);
    }

    function testClaimRewards() public {
        vm.prank(user1);
        stakingContract.stake(100 ether);

        vm.warp(block.timestamp + 10);

        vm.prank(user1);
        stakingContract.claimRewards();

        uint256 expectedRewards = (100 ether * rewardRate * 10) / 1e18;
        assertEq(stakingToken.balanceOf(user1), 900 ether + expectedRewards);
    }

    function testCannotClaimRewardsIfNoneAvailable() public {
        vm.prank(user1);
        stakingContract.stake(100 ether);

        vm.prank(user1);
        vm.expectRevert("No rewards available");
        stakingContract.claimRewards();
    }

    function testUpdateRewards() public {
        vm.prank(user1);
        stakingContract.stake(100 ether);

        vm.warp(block.timestamp + 5); //fastforward 5 seconds

        vm.prank(user1);
        stakingContract.stake(50 ether);

        uint256 expectedRewards = (100 ether * rewardRate * 5) / 1e18;
        assertEq(stakingContract.rewardDebt(user1), expectedRewards);
        assertEq(stakingContract.stakedBalance(user1), 150 ether);
    }
}
