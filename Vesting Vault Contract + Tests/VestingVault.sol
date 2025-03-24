//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VestingVault is Ownable {
    IERC20 public token;
    address public beneficiary;

    uint256 public startTime;
    uint256 public vestingDuration;
    uint256 public cliffDuration;

    uint256 public totalDeposited;
    uint256 public totalClaimed;
    bool public revoked;

    event TokensDeposited(uint256);
    event TokensWithdrawn(uint256 amount);
    event VestingRevoked(uint256 remainingTokens);

    constructor(
        address _token,
        address _beneficiary,
        uint256 _vestingDuration,
        uint256 _cliffDuration
    ) {
        require(_token != address(0), "Token address cannot be zero");
        require(_beneficiary != address(0), "Beneficiary cannot be zero");
        require(_vestingDuration > 0, "Vesting must be greater than zero");
        require(_cliffDuration <= _vestingDuration, "Cliff cannot exceed vesting");

        token = IERC20(_token);
        beneficiary = _beneficiary;
        vestingDuration = _vestingDuration;
        cliffDuration = _cliffDuration;
        startTime = block.timestamp;
    }

    function deposit(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(!revoked, "Vesting revoked");

        token.transferFrom(msg.sender, address(this), amount);
        totalDeposited += amount;

        emit TokensDeposited(amount);
    }

    function claim() external {
        require(msg.sender == beneficiary, "Not beneficiary");
        require(block.timestamp >= startTime + cliffDuration, "Cliff not reached");
        require(!revoked, "Vesting revoked");

        uint256 vested = _vestedAmount();
        uint256 claimable = vested - totalClaimed;
        require(claimable > 0, "No tokens to claim");

        totalClaimed += claimable;
        token.transfer(beneficiary, claimable);

        emit TokensWithdrawn(claimable);
    }

    function revoke() external onlyOwner {
        require(!revoked, "Already revoked");

        uint256 vested = _vestedAmount();
        uint256 unvested = totalDeposited - vested;

        revoked = true;

        if (unvested > 0) {
            token.transfer(owner(), unvested);
        }

        emit VestingRevoked(unvested);
    }

    function _vestedAmount() internal view returns (uint256) {
        if (block.timestamp < startTime + cliffDuration) {
            return 0;
        } else if (block.timestamp <= startTime + vestingDuration) {
            return totalDeposited;
        } else {
            uint256 timeElapsed = block.timestamp - startTime;
            return (totalDeposited * timeElapsed) / vestingDuration;
        }
    }

    function claimableAmount() external view returns (uint256) {
        if (revoked) return 0;
        uint256 vested = _vestedAmount();
        return vested > totalClaimed ? vested - totalClaimed : 0;
    }
}
