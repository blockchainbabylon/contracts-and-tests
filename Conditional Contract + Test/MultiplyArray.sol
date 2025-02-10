//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract MultiplyArray {
    uint[] public numbers = [2, 3, 4];

    function multiplyNumber() public view returns (uint) {
        uint product = 1;

        for (uint i = 0; i < numbers.length; i++) {
            product *= numbers[i];
        }

        return product;
    }
}