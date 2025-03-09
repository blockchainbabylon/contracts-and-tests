//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public quorum;

    struct Transaction {
        address to;
        uint256 amount;
        string description;
        bool executed;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "You are not the owner");
        _;
    }

    modifier validTransactionId(uint256 transactionId) {
        require(transactionId < transactions.length, "Invalid transaction ID");
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, "Transaction already executed");
        _;
    }

    modifier hasNotApproved(uint256 transactionId) {
        require(!transactions[transactionId].approvals[msg.sender], "You have already approved this transaction");
        _;
    }

    event TransactionProposed(uint256 transactionId, address indexed proposer, address to, uint256 amount, string description);
    event TransactionApproved(uint256 transactionId, address indexed approver);
    event TransactionExecuted(uint256 transactionId, address indexed executor);
    event TransactionRevoked(uint256 transactionId, address indexed revoker);
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event QuorumChanged(uint256 newQuorum);

    constructor(address[] memory initialOwners, uint256 _quorum) {
        require(initialOwners.length > 0, "Atleast one owner required");
        require(_quorum > 0 && _quorum <= initialOwners.length, "Invalid quorum");

        for (uint256 i = 0; i < initialOwners.length; i++) {
            address newOwner = initialOwners[i];
            require(!isOwner[newOwner], "Address is already an owner");
            owners.push(newOwner);
            isOwner[newOwner] = true;
        }
        quorum = _quorum;
    }

    function proposeTransaction(address to, uint256 amount, string memory description) public onlyOwner {
        uint256 transactionId = transactions.length;
        Transaction storage newTransaction = transactions.push();
        newTransaction.to = to;
        newTransaction.amount = amount;
        newTransaction.description = description;
        newTransaction.executed = false;
        newTransaction.approvalCount = 0;

        emit TransactionProposed(transactionId, msg.sender, to, amount, description);
    }

    function approveTransaction(uint256 transactionId) public onlyOwner validTransactionId(transactionId) notExecuted(transactionId) hasNotApproved(transactionId) {
        Transaction storage txn = transactions[transactionId];
        txn.approvals[msg.sender] = true;
        txn.approvalCount += 1;

        emit TransactionApproved(transactionId, msg.sender);

        if (txn.approvalCount >= quorum) {
            executeTransaction(transactionId);
        }
    }

    function revokeApproval(uint256 transactionId) public onlyOwner validTransactionId(transactionId) notExecuted(transactionId) {
        Transaction storage txn = transactions[transactionId];
        require(txn.approvals[msg.sender], "You have not approved this transaction");

        txn.approvals[msg.sender] = false;
        txn.approvalCount -= 1;

        emit TransactionRevoked(transactionId, msg.sender);
    }

    function executeTransaction(uint256 transactionId) public onlyOwner validTransactionId(transactionId) notExecuted(transactionId) {
        Transaction storage txn = transactions[transactionId];
        require(txn.approvalCount >= quorum, "Not enough approvals");

        txn.executed = true;
        payable(txn.to).transfer(txn.amount);

        emit TransactionExecuted(transactionId, msg.sender);
    }

    function addOwner(address newOwner) public onlyOwner {
        require(!isOwner[newOwner], "Address is already an owner");
        owners.push(newOwner);
        isOwner[newOwner] = true;

        emit OwnerAdded(newOwner);
    }

    function removeOwner(address ownerToRemove) public onlyOwner {
        require(isOwner[ownerToRemove], "Address is not an owner");

        isOwner[ownerToRemove] = false;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }

        emit OwnerRemoved(ownerToRemove);
    }

    function setQuorum(uint256 newQuorum) public onlyOwner {
        require(newQuorum > 0 && newQuorum <= owners.length, "Invalid quorum");
        quorum = newQuorum;

        emit QuorumChanged(newQuorum);
    }

    function getTransactionCount() public view returns(uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 transactionId) public view returns(address to, uint256 amount, string memory description, bool executed, uint256 approvalCount) {
        Transaction storage txn = transactions[transactionId];
        return (txn.to, txn.amount, txn.description, txn.executed, txn.approvalCount);
    }

    function getOwnersCount() public view returns(uint256) {
        return owners.length;
    }

    function getOwner(uint256 index) public view returns(address) {
        return owners[index];
    }
}
