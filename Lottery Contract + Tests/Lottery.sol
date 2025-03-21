//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Lottery {
    address public manager;
    uint256 public entryFee;
    address[] public participants;
    bool public lotteryActive;

    event LotteryStarted(uint256 entryFee);
    event LotteryEnded(address winner);
    event ParticipantEntered(address participant);

    constructor(uint256 _entryFee) {
        manager = msg.sender;
        entryFee = _entryFee;
        lotteryActive = false;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can perform this action");
        _;
    }

    modifier lotteryIsActive() {
        require(lotteryActive, "Lottery is not active");
        _;
    }

    function startLottery() public onlyManager {
        require(!lotteryActive, "Lottery is already active");
        lotteryActive = true;
        delete participants; //we want lottery to begin with fresh start
        
        emit LotteryStarted(entryFee);
    }

    function enterLottery() public payable lotteryIsActive {
        require(msg.value == entryFee, "Incorrect entry fee");
        participants.push(msg.sender);
        
        emit ParticipantEntered(msg.sender);
    }

    function endLottery() public onlyManager lotteryIsActive {
        require(participants.length > 0, "No participants in the lottery");

        uint256 winnerIndex = uint256(blockhash(block.number - 1)) % participants.length; //taking hash of previous block
        address winner = participants[winnerIndex];

        payable(winner).transfer(address(this).balance);
        lotteryActive = false;

        emit LotteryEnded(winner);
    }

    function getLotteryStatus() public view returns(bool, uint256) {
        return (lotteryActive, participants.length);
    }

    function getParticipants() public view returns(address[] memory) {
        return participants;
    }
}
