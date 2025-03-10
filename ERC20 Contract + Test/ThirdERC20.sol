//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract CustomERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    address public treasuryWallet;
    uint256 public taxFee = 2;
    uint256 public maxTxAmount;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private blacklist;
    mapping(address => bool) private excludedFromTax;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Blacklisted(address indexed account, bool value);
    event TaxFeeUpdated(uint256 newTaxFee);
    event MaxTxAmountUpdated(uint256 newMaxTxAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _treasuryWallet,
        uint256 _maxTxAmount
    ) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        treasuryWallet = _treasuryWallet;
        maxTxAmount = _maxTxAmount;

        _mint(msg.sender, _initialSupply * 10 ** decimals);
        excludedFromTax[owner] = true;
        excludedFromTax[treasuryWallet] = true;
    }

    function balanceOf(address account) public view returns(uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns(bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns(bool) {
        allowances[msg.spender][amount] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view returns(uint256) {
        return allowances[_owner][spender]; //returns amount approved user can spend
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns(bool) {
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");
        allowances[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(!blacklist[sender] && !blacklist[recipient], "Blacklisted address");
        require(amount <= maxTxAmount, "Exceeds max transaction limit");
        require(balances[sender] >= amount, "Insufficient balance");

        uint256 taxAmount = 0;
        if (!excludedFromTax[sender] && !excludedFromTax[recipient]) {
            taxAmount = (amount * taxFee) / 100;
            balances[treasuryWallet] += taxAmount;
            emit Transfer(sender, treasuryWallet, taxAmount);
        }

        balances[sender] -= amount;
        balances[recipient] += (amount - taxAmount);

        emit Transfer(sender, recipient, amount - taxAmount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal {
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens to burn");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function setBlackList(address account, bool value) external onlyOwner {
        blacklist[account] = value;
        emit Blacklisted(account, value);
    }

    function setTaxFee(uint256 newTaxFee) external onlyOwner {
        require(newTaxFee <= 10, "Tax too high");
        taxFee = newTaxFee;
        emit TaxFeeUpdated(newTaxFee);
    }

    function setMaxTxAmount(uint256 newMaxTxAmount) external onlyOwner {
        require(newMaxTxAmount > 0, "Must be greater than zero");
        maxTxAmount = newMaxTxAmount;
        emit MaxTxAmountUpdated(newMaxTxAmount);
    }
}
