//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/Storing.sol";

contract StoringTest is Test {
    Storing storing;

    function setUp() public {
        storing = new Storing();
    }

    function testSetAndGet() public {
        uint256 value = 42;
        storing.set(value);
        uint256 storeValue = storing.get();
        assertEq(storedValue, value);
    }

    function testInitialValue() public {
        uint256 initialValue = storing.get();
        assertEq(initialValue, 0);
    }
}