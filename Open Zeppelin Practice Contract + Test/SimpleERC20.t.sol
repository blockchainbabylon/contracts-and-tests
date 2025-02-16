//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/SimpleERC20.sol";

contract SimpleERC20Test is Test {
    SimpleERC20 token;
    address owner = address(0x123);
    address recipient = address(0x456);

    function setUp() public {
        vm.prank(owner);
        token = new SimpleERC20(1000 * 10 * 18);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1000 * 10 * 18);
        assertEq(token.balanceOf(owner), 1000 * 10 ** 18);
    }

    function testMint() public {
        vm.prank(owner);
        token.mint(recipient, 500 * 10 ** 18);
        assertEq(token.balanceOf(recipient), 500 * 10 ** 18);
        assertEq(token.totalSupply(), 1500 * 10 ** 18);
    }

    function testMintNotOwner() public {
        vm.prank(recipient);
        vm.expectRevert("Ownable: caller is not the owner");
        token.mint(recipient, 500 * 10 ** 18);
    }
}
