//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/SecondERC20.sol";

contract MyTokenTest is Test {
    MyToken token;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);
    uint256 initialSupply = 1000 ether;

    function setUp() public {
        vm.prank(owner);
        token = new MyToken(initialSupply);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), initialSupply);
        assertEq(token.balanceOf(owner), initalSupply);
    }

    function testTransferWhenActive() public {
        vm.prank(owner);
        token.transfer(user1, 100 ether);

        assertEq(token.balanceOf(owner), 900 ether);
        assertEq(token.balanceOf(user1), 100 ether);
    }

    function testTransferWhenPaused() public {
        vm.prank(owner);
        token.setTokenState(MyToken.TokenState.Paused);

        vm.prank(owner);
        vm.expectRevert("Token is not active");
        token.transfer(user1, 100 ether);
    }

    function testFreezeAccount() public {
        vm.prank(owner);
        token.freezeAccount(user1);

        vm.prank(user1);
        vm.expectRevert("Your account is frozen");
        token.transfer(user2, 50 ether);
    }

    function testUnfreezeAccount() public {
        vm.prank(owner);
        token.transfer(user1, 100 ether);
        
        vm.prank(owner);
        token.freezeAccount(user1);

        vm.prank(owner);
        token.unfreezeAccount(user1);

        vm.prank(user1);
        token.transfer(user2, 50 ether);

        assertEq(token.balanceOf(user1), 50 ether);
        assertEq(token.balanceOf(user2), 50 ether);
    }

    function testTransferFromWhenActive() public {
        vm.prank(owner);
        token.transfer(user1, 100 ether);

        vm.prank(user1);
        token.approve(user2, 50 ether);

        vm.prank(user2);
        token.transferFrom(user1, user2, 50 ether);

        assertEq(token.balanceOf(user1), 50 ether);
        assertEq(token.balanceOf(user2), 50 ether);
    }

    function testTransferWhenPaused() public {
        vm.prank(owner);
        token.transfer(user1, 100 ether);

        vm.prank(user1);
        token.approve(user2, 50 ether);
        
        vm.prank(owner);
        token.setTokenState(MyToken.TokenState.Paused);

        vm.prank(user2);
        vm.expectRevert("Token is not active");
        token.transferFrom(user1, user2, 50 ether);
    }

    function testTransferFromFrozenAccount() public {
        vm.prank(owner);
        token.transfer(user1, 100 ether);

        vm.prank(user1);
        token.approve(user2, 50 ether);

        vm.prank(owner);
        token.freezeAccount(user1);

        vm.prank(user2);
        vm.expectRevert("Sender's account is frozen");
        token.transferFrom(user1, user2, 50 ether);
    }


}