//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/Lottery.sol";

contract LotteryTest is Test {
    Lottery lottery;
    address manager = address(0x123);
    address participant1 = address(0x456);
    address participant2 = address(0x789);
    address participant3 = address(0xABC);
    uint256 entryFee = 0.1 ether;

    function setUp() public {
        vm.prank(manager);
        lottery = new Lottery(entryFee);

        vm.deal(participant1, 1 ether);
        vm.deal(participant2, 1 ether);
        vm.deal(participant3, 1 ether);
    }

    function testInitializeLottery() public {
        assertEq(lottery.manager(), manager);
        assertEq(lottery.entryFee(), entryFee);
        assertFalse(lottery.lotteryActive());
    }

    function testStartLottery() public {
        vm.prank(manager);
        lottery.startLotter();

        (bool lotteryActive, uint256 participantsCount) = lottery.getLotteryStatus();
        assertTrue(lotteryActive);
        assertEq(participantsCount, 0);
    }

    function testCannotStartLotteryTwice() public {
        vm.prank(manager);
        lottery.startLottery();

        vm.prank(manager);
        vm.expectRevert("Lottery is already active");
        lottery.startLottery();
    }

    function testEnterLottery() public {
        vm.prank(manager);
        lottery.startLottery();

        vm.prank(participant1);
        lottery.enterLottery{ value: entryFee}();

        vm.prank(participant2);
        lottery.enterLottery{ value: entryFee}();

        address[] memory participants = lottery.getParticipants();
        assertEq(participants.length, 2);
        assrtEq(participants[0], participant1);
        assertEq(participants[1], participant2);
    }

    function testCannotEnterLotteryWithIncorrectFee() public {
        vm.prank(manager);
        lottery.startLottery();

        vm.prank(participant1);
        vm.expectRevert("Incorrect entry fee");
        lottery.enterLottery{ value: 0.2 ether }();
    }

    function testEndLottery() public {
        vm.prank(manager);
        lottery.startLottery();

        vm.prank(participant1);
        lottery.enterLottery{ value: entryFee }();

        vm.prank(participant2);
        lottery.enterLottery{ value: entryFee }();

        vm.prank(participant3);
        lottery.enterLottery{ value: entryFee }();

        //address balances before lotteryEnd
        uint256 initialBalance = address(participant1).balance + address(participant2).balance + address(participant3).balance;

        vm.prank(manager);
        lottery.endLottery();

        (bool lotteryActive, uint256 participantsCount) = lottery.getLotteryStatus();
        assertFalse(lotteryActive);
        assertEq(participantsCount, 0);

        //verifies one of the participants received the prize
        uint256 finalBalance = address(participant1).balance + address(participant2).balance + address(participant3).balance;
        assertEq(finalBalance, intialBalance + 0.3 ether);
    }

    function testCannotEndLotteryWithoutParticipants() public {
        vm.prank(manager);
        lottery.startLottery();

        vm.prank(manager);
        vm.expectRevert("No participants in the lottery");
        lottery.endLottery();
    }

    function testOnlyManagerCanStartLottery() public {
        vm.prank(participant1);
        vm.expectRevert("Only the manager can perform this action");
        lottery.startLottery();
    }

    function testOnlyManagerCanEndLottery() public {
        vm.prank(manager);
        lottery.startLottery();

        vm.prank(participant1);
        lottery.endLottery{value: entryFee}();

        vm.prank(participant1);
        vm.expectRevert("Only the manager can perform this action");
        lottery.endLottery();
    }
}
