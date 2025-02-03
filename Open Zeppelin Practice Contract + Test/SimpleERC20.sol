//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("SimpleToken", "STK") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}