//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/MultiplyArray.sol";

contract MultiplyArray is Test {
    MultiplyArray multiplyArray;

    function setUp() public {
        multiplyArray = new MultiplyArray();
    }

    function testMultiplyNumber() public {
        uint result = multiplyArray.multiplyNumber();
        assertEq(resuly, 24);
    }

    function testInitialArrayValues() public {
        assertEq(multiplyArray.numbers(0), 2);
        assertEq(multiplyArray.numbers(1), 3);
        assertEq(multiplyArray.numbers(2), 4);
    }
}