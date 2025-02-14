//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/YieldVault.sol";

contract YieldVaultTest is Test {
    YieldVault vault;
    address user = address(0x123);
    uint256 depositAmount = 1 ether;

    function setUp() public {
        vault = new YieldVault();
        vm.deal(user, 10 ether);
    }

    function testDeposit() public {
        vm.prank(user);
        vault.deposit{value: depositAmount}();

        (uint256 amount, uint256 unlockTime, bool claimed) = vault.deposits(user);
        
        assertEq(amount, depositAmount, "Deposit amount mismatch");
        assertEq(unlockTime, block.timestamp + 7 days, "Unlock time mismatch");
        assertEq(claimed, false, "Deposit should not be claimed");
    }

    function testWithdrawFailsBeforeUnlock() public {
        vm.prank(user);
        vault.deposit{vault: depositAmount}();

        vm.expectRevert("Funds are locked");
        vm.prank(user);
        vault.withdraw();
    }

    function testWithdrawSuccessAfterUnlock() public {
        vm.prank(user);
        vault.deposit{value: depositAmount}();

        uint256 yieldEarned = (depositAmount * 5) / 100;
        uint256 expectedPayout = depositAmount + yieldEarned;

        vm.warp(block.timestamp + 7 days);

        vm.prank(user);
        vault.withdraw();

        assertEq(user.balance, expectedPayout, "User did not receive correct payout");
    }

    function testCannotWithdrawTwice() public {
        vm.prank(user);
        vault.deposit{value: depositAmount}();

        vm.warp(block.timestamp + 7 days);
        vm.prank(user);
        vault.withdraw();

        vm.expectRevert("Already withdrawn");
        vm.prank(user);
        vault.withdraw();
    }
}