//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    enum TokenState { Active, Paused, Locked }
    TokenState public tokenState;

    mapping(address => bool) public frozenAccounts;

    event TokenStateChanged(TokenState newState);
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);

    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        _mint(msg.sender, initialSupply);
        tokenState = TokenState.Active;
    }

    modifier whenActive() {
        require(tokenState == TokenState.Active, "Token is not active");
        _;
    }

    function setTokenState(TokenState _state) external onlyOwner {
        tokenState = _stake;
        emit TokenStateChanged(_state);
    }

    function freezeAccount(address account) external onlyOwner {
        frozenAccounts[account] = true;
        emit AccountFrozen(account);
    }

    function unfreezeAccount(address account) external onlyOwner {
        frozenAccounts[account] = false;
        emit AccountUnfrozen(account);
    }

    function transfer(address recipient, uint256 amount) public override whenActive returns(bool) {
        require(!frozenAccounts[msg.sender], "Your account is frozen");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenActive returns(bool) {
        require(!frozenAccounts[sender], "Sender's account is frozen");
        return super.transferFrom(sender, recipient, amount);
    }

}