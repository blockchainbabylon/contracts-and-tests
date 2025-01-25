//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Conditionals {
    uint256 storedValue = 8;

    function ifelse(uint256 _storedValue) public view returns(bool) {
        if(storedValue == _storedValue) {
            return false; 
        } else if(_storedValue == 7) {
            return false;
        } else {
            return true;
        }
    }
}
