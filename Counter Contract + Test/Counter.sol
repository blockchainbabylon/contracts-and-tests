//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint256 private count;

    event CounterIncremented(uint256 newCount);
    event CounterDecremented(uint256 newCount);

    function getCount() public view returns (uint256) {
        return count;
    }

    function increment() public {
        count += 1;
        emit CounterIncremented(count);
    }

    function decrement() public {
        require(count > 0, "Counter: counter caannot be less than zero");
        count -= 1;
        emit CounterDecremented(count);
    }
}
