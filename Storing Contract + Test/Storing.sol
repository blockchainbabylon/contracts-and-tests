//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Storing {
    uint256 storedValue;

    function set(uint256 _storedValue) public {
        storedValue = _storedValue;
    }

    function get() public view returns(uint256) {
        return storedValue;
    }


}