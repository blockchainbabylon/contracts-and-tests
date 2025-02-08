//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "./src/Conditionals.sol";

contract ConditionalsTest is Test {
    Conditionals conditionals;

    function setUp() public {
        conditionals = new Conditionals();
    }

    function testIfElseWithEqualValue() public {
        bool result = conditionals.ifelse(8);
        assertEq(result, false, "Expected false when storedValue == _storedValue");
    }

    function testIfElseWithSeven() public {
        bool result = conditionals.ifelse(7);
        assertEq(result, false, "Expected false when storedValue == _storedValue");
    }

    function testIfElseWithOtherValue() {
        bool result = conditionals.ifelse(2);
        assertEq(result, true, "Expected true when _storedValue is neither storedValue nor 7");
    }
}