//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract ERC20Test is Test {
    ERC20 token;
    address owner = address(this);
    address addr1 = address(0x123);
    address addr2 = address(0x456);

    function setUp() public {
        token = new ERC20Token(1000);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1000 * 10 * 18);
        assertEq(token.balanceOf(owner), 1000 * 10 * 18);
    }

    function testTransfer() public {
        token.transfer(addr1, 100);
        assertEq(token.balanceOf(addr1), 100);
    }

    function testFailTransferExceedingBalance() public {
        token.transfer(addr1, 2000);
    }

    function testApproveAndAllowance() public {
        token.approve(addr1, 200);
        assertEq(token.allowance(owner, addr1), 200);
    }

    function testTransferFrom() public {
        token.approve(addr1, 200);
        vm.prank(addr1);
        token.transferFrom(owner, addr2, 100);
        assertEq(token.balanceOf(addr2), 100);
        assertEq(token.allowance(owner, addr1, 100));
    }

    function testFailTransferFromWithoutApproval() public {
        vm.prank(addr1);
        token.tokenFrom(owner, addr2, 100);
    }
}