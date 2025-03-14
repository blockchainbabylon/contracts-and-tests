//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract DeFiDAO {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        uint256 newRewardRate;
    }

    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakeTimestamp;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public totalSupply;
    uint256 public proposalCount;
    uint256 public votingDuration = 3 days;
    uint256 public quorumPercentage = 20;
    uint256 public minStakedAmount = 100 * 10**18;
    uint256 public rewardRate = 5;
    uint256 public constant REWARD_PERIOD = 7 days;

    address public admin;
    uint256 public treasuryBalance;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool vote, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amonut, uint256 reward);
    event Minted(address indexed to, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);
    event TreasuryFunded(uint256 amount);

    constructor() {
        admin = msg.sender;
        mint(admin, 1000000 * 10**18);
    } 

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function mint(address to, uint256 amount) public onlyAdmin {
        balances[to] += amount;
        totalSupply += amount;
        emit Minted(to, amount);
    }

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transferred(msg.sender, to, amount);
    }

    function depositETH() external payable {
        require(msg.value > 0, "Must send ETH");
        uint256 tokensToMint = msg.value * 100;
        mint(msg.sender, tokensToMint);
    }

    function stake(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        stakedBalance[msg.sender] += amount;
        stakeTimestamp[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(stakedBalance[msg.sender] >= amount, "Not enough staked tokens");

        uint256 stakingTime = block.timestamp - stakeTimestamp[msg.sender];
        require(stakingTime >= REWARD_PERIOD, "Must stake for at least 7 days");

        uint256 reward = (amount * rewardRate) / 100;
        uint256 treasuryCut = reward / 5;

        treasuryBalance += treasuryCut;
        balances[msg.sender] += amount + (reward - treasuryCut);
        stakedBalance[msg.sender] -= amount;

        emit Unstaked(msg.sender, amount, reward);
        emit TreasuryFunded(treasuryCut);
    }

    function createProposal(string memory description, uint256 newRewardRate) external returns(uint256) {
        require(stakedBalance[msg.sender] >= minStakedAmount, "Must stake min amount");

        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            executed: false,
            newRewardRate: newRewardRate
        });

        emit ProposalCreated(proposalId, msg.sender, description, proposals[proposalId].endTime);
        return proposalId;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.endTime, "Voting over");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 votingPower = stakedBalance[msg.sender];
        require(votingPower > 0, "No governance power");

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        hasVoted[proposalId][msg.sender] = true;
        emit Voted(proposalId, msg.sender, support, votingPower);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting still active");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalSupply * quorumPercentage) / 100;
        bool passed = proposal.votesFor > proposal.votesAgainst && totalVotes >= quorum;

        if (passed) {
            rewardRate = proposal.newRewardRate;
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, passed);
    }

    function withTreasury(uint256 amount, address to) external onlyAdmin {
        require(amount <= treasuryBalance, "Not enough treasury funds");
        treasuryBalance -= amount;
        payable(to).transfer(amount);
        emit TreasuryFunded(amount);
    }

    receive() external payable {}
}