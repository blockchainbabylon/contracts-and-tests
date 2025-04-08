// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/DynamicReputationToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract DynamicReputationTokenTest is Test {
    DynamicReputationToken reputationToken;
    ERC20Mock rewardToken;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);
    address user3 = address(0xABC);

    function setUp() public {
        // Deploy mock ERC20 token
        rewardToken = new ERC20Mock("Reward Token", "RWT", 1_000_000 ether);

        // Deploy the DynamicReputationToken contract
        vm.prank(owner);
        reputationToken = new DynamicReputationToken(address(rewardToken));

        // Fund the contract with reward tokens
        rewardToken.transfer(address(reputationToken), 100_000 ether);
    }

    function testAwardReputation() public {
        vm.prank(owner);
        reputationToken.awardReputation(user1, 100);

        uint256 reputation = reputationToken.reputationBalance(user1);
        assertEq(reputation, 100, "Reputation should be 100");

        address[] memory holders = reputationToken.getReputationHolders();
        assertEq(holders.length, 1, "There should be 1 reputation holder");
        assertEq(holders[0], user1, "User1 should be the reputation holder");
    }

    function testSetCollectiveGoalMet() public {
        vm.prank(owner);
        reputationToken.awardReputation(user1, 100);
        reputationToken.awardReputation(user2, 200);

        vm.prank(owner);
        reputationToken.setCollectiveGoalMet(10_000 ether);

        uint256 rewardPerHolder = reputationToken.rewardAmountPerHolder();
        assertEq(rewardPerHolder, 5_000 ether, "Reward per holder should be 5000 ether");
    }

    function testClaimReward() public {
        vm.prank(owner);
        reputationToken.awardReputation(user1, 100);
        reputationToken.awardReputation(user2, 200);

        vm.prank(owner);
        reputationToken.setCollectiveGoalMet(10_000 ether);

        vm.prank(user1);
        reputationToken.claimReward();

        uint256 user1Balance = rewardToken.balanceOf(user1);
        assertEq(user1Balance, 5_000 ether, "User1 should receive 5000 ether reward");

        uint256 reputation = reputationToken.reputationBalance(user1);
        assertEq(reputation, 0, "User1's reputation should be reset to 0");
    }

    function testCannotClaimRewardBeforeGoalAchieved() public {
        vm.prank(owner);
        reputationToken.awardReputation(user1, 100);

        vm.prank(user1);
        vm.expectRevert("Collective goal not yet achieved");
        reputationToken.claimReward();
    }

    function testMarkParticipation() public {
        vm.prank(owner);
        reputationToken.markParticipation(user1);

        bool participated = reputationToken.hasParticipatedInEvent(user1);
        assertTrue(participated, "User1 should be marked as participated");
    }

    function testHasAccessToExclusiveFeature() public {
        vm.prank(owner);
        reputationToken.awardReputation(user1, 100);
        reputationToken.awardReputation(user2, 200);
        reputationToken.awardReputation(user3, 300);

        vm.prank(owner);
        reputationToken.markParticipation(user1);
        reputationToken.markParticipation(user2);
        reputationToken.markParticipation(user3);

        bool access = reputationToken.hasAccessToExclusiveFeature(user1);
        assertTrue(access, "User1 should have access to the exclusive feature");
    }

    function testHasNoAccessToExclusiveFeature() public {
        vm.prank(owner);
        reputationToken.awardReputation(user1, 100);

        bool access = reputationToken.hasAccessToExclusiveFeature(user1);
        assertFalse(access, "User1 should not have access without enough participants");
    }
}
