//SPDX-Licnese-Identifier: MIT
pragma solidity 0.8.26;

contract Lending {
    struct User {
        uint256 deposit;
        uint256 borrowed;
        uint256 interestTimestamp;
    }

    mapping(address => User) public users;
    uint256 public constant INTEREST_RATE = 5;
    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant LIQUIDATION_THRESHOLD = 120;

    function deposit() external payable {
        User storage user = users[msg.sender];
        _accrueInterest(msg.sender);
        user.deposit += msg.value;
    }

    function borrow(uint256 amount) external {
        User storage user = users[msg.sender];
        _accrueInterest(msg.sender);
        require(_collateralValue(msg.sender) * 100 / user.borrowed >= COLLATERAL_RATIO, "Insufficient collateral");
        user.borrowed += amount;
        payable(msg.sender).transfer(amount);
    }

    function repay() external payable {
        User storage user = users[msg.sender];
        _accrueInterest(msg.sender);
        require(user.borrowed >= msg.value, "Overpayment not allowed");
        user.borrowed -= msg.value;
    }

    function liquidate(address debtor) external {
        User storage user = users[debtor];
        require(_collateralValue(debtor) * 100 / user.borrowed < LIQUIDATION_THRESHOLD, "Cannot liquidate");
        payable(msg.sender).transfer(user.deposit);
        delete users[debtor];
    }

    function _accrueInterest(address account) internal {
        User storage user = users[account];
        if (user.borrowed > 0) {
            uint256 timeElapsed = block.timestamp - user.interestTimestamp;
            uint256 interest = (user.borrowed * INTEREST_RATE * timeElapsed) / (365 days * 100);
            user.borrowed += interest;
        }
        user.interestTimestamp = block.timestamp;
    }

    function _collateralValue(address account) internal view returns(uint256) {
        return users[account].deposit;
    }
}
