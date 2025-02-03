//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Escrow2 {
    address public buyer;
    address public arbiter;
    address public seller;
    uint256 public amount;
    bool public isDisputed;
    bool public isComplete;
    bool public isRefunded;

    enum State { Created, Locked, Released, Refunded, Disputed }
    State public currentState;

    event Deposit(address indexed buyer, uint256 amount);
    event Release(address indexed seller, uint256 amount);
    event Refund(address indexed buyer, uint256 amount);
    event Dispute(address indexed arbiter, uint256 amount);
    event ResolveDispute(address indexed arbiter, bool decision);

    constructor(address _seller, address _arbiter, uint256 _amount) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        amount = _amount;
        currentState = State.Created;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this");
        _;
    }

    modifier inState(State _state) {
        require(currentState == _state, "Invalid contract state");
        _;
    }

    function deposit() external payable onlyBuyer inState(State.Created) {
        require(msg.value == amount, "Incorrect deposit amount");
        currentState = State.Locked;
        emit Deposit(buyer, msg.value);
    }

    function release() external onlyBuyer inState(State.Locked) {
        currentState = State.Released;
        payable(seller).transfer(amount);
        emit Release(seller, amount);
    }

    function refund() external onlySeller inState(State.Locked) {
        currentState = State.Refunded;
        payable(buyer).transfer(amount);
        emit Refund(buyer, amount);
    }

    function dispute() external onlyBuyer inState(State.Locked) {
        currentState = State.Disputed;
        isDisputed = true;
        emit Dispute(arbiter, amount);
    }

    function resolveDispute(bool decision) external onlyArbiter inState(State.Disputed) {
        require(isDisputed, "No dispute to resolve");
        isDisputed = false;
        currentState = State.Released;

        if (decision) {
            payable(seller).transfer(amount);
            emit ResolveDispute(arbiter, true);
        } else {
            payable(buyer).transfer(amount);
            emit ResolveDispute(arbiter, false);
        }
    }

    function getContractState() external view returns(State) {
        return currentState;
    }
}