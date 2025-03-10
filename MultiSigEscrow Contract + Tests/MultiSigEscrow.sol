//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract MultiSigContract {
    address[] public signers;
    uint256 public requiredApprovals;

    struct Transaction {
        address payable recipient;
        uint256 amount;
        uint256 approvals;
        bool executed;
        mapping(address => bool) isApproved;
    }

    Transaction[] public transactions;
    mapping(address => bool) public isSigner;

    event Deposit(address indexed sender, uint256 amount);
    event TransactionCreated(uint256 indexedtxId, address indexed recipient, uint256 amount);
    event Approved(address indexed signer, uint256 indexed txId);
    event Executed(uint256 indexed txId);

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    constructor(address[] memory _signers, uint256 _requiredApprovals) {
        require(_signers.length > 0,"At least one signer require");
        require(_requiredApprovals > 0 && _requiredApprovals <= _signers.length, "Invalid approval count");

        for (uint256 i = 0; i < _signers.length; i++) {
            require(!isSigner[_signers[i]], "Duplicate signer");
            isSigner[_signers[i]] = true;
        }
        signers = _signers;
        requiredApprovals = _requiredApprovals;
    }

    function deposit() external payable {
        require(msg.value > 0, "Must send ether");
        emit Deposit(msg.sender, msg.value);
    }

    function createTransaction(address payable _recipient, uint256 _amount) external onlySigner {
        require(address(this).balance >= _amount, "Insufficient balance");

        Transaction storage txn = transactions.push();
        txn.recipient = _recipient;
        txn.amount = _amount;
        txn.approvals = 0;
        txn.executed = false;

        emit TransactionCreated(transactions.length - 1, _recipient, _amount);
    }

    function approveTransaction(uint256 _txId) external onlySigner {
        Transaction storage txn = transactions[_txId];

        require(!txn.executed, "Already executed");
        require(!txn.isApproved[msg.sender], "Already approved");

        txn.isApproved[msg.sender] = true;
        txn.approvals++;

        emit Approved(msg.sender, _txId);

        if (txn.approvals >= requiredApprovals) {
            executeTransaction(_txId);
        }
    }
    
    function executeTransaction(uint256 _txId) internal {
        Transaction storage txn = transactions[_txId];

        require(txn.approvals >= requiredApprovals, "Not enough approvals");
        require(!txn.executed, "Already executed");

        txn.executed = true;
        txn.recipient.transfer(txn.amount);

        emit Executed(_txId);
    }

    function getTransactionCount() external view returns(uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txId) external view returns(
        address recipient,
        uint256 amount,
        uint256 approvals,
        bool executed
    ) {
        Transaction storage txn = transactions[_txId];
        return (txn.recipient, txn.amount, txn.approvals, txn.executed);
    }
}
