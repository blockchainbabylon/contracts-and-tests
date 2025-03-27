//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/VestingVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, address initialAccount, uint256 initialBalance)
    ERC20(name, symbol)
    {
        _mint(initialAccount, initialBalance);
    }
}

contract VestingVault is Test {
    VestingVault vestingVault;
    ERC20Mock token;
    address owner = address(0x123);
    address beneficiary = address(0x456);
    uint256 vestingDuration = 365 days;
    uint256 cliffDuration = 30 days;

    function setUp() public {
        token = new ERC20Mock("Test Token", "TT", owner, 1_000_000 ether);

        vm.prank(owner);
        vestingVault = new VestingVault(address(token), beneficiary, vestingDuration, cliffDuration);

        vm.prank(owner);
        token.approve(address(vestingVault), type(uint256).max);
    }

    function testDepositTokens() public {
        uint256 depositAmount = 100_000 ether;

        vm.prank(owner);
        vestingVault.deposit(depositAmount);

        assertEq(vestingVault.totalDeposited(), depositAmount);
        assertEq(token.balanceOf(address(vestingVault)), depositAmount);
    }

    function testCannotDepositAfterRevoke() public {
        uint256 depositAmount = 100_000 ether;

        vm.prank(owner);
        vestingVault.deposit(depositAmount);

        vm.prank(owner);
        vestingVault.revoke();

        vm.prank(owner);
        vm.expectRevert("Vesting revoked");
        vestingVault.deposit(depositAmount);
    }

    function testClaimTokensAfterCliff() public {
        uint256 depositAmount = 100_000 ether;

        vm.prank(owner);
        vestingVault.deposit(depositAmount);

        vm.warp(block.timestamp + cliffDuration);

        uint256 claimable = vestingVault.claimableAmount();
        assertGt(claimable, 0);

        vm.prank(beneficiary);
        vestingvault.claim();

        assertEq(vestingvault.totalClaimed(), claimable);
        assertEq(token.balanceOf(beneficiary), claimable);
    }

    function testCannotClaimBeforeCliff() public {
        uint256 depositAmount = 100_000 ether;

        vm.prank(owner);
        vestingVault.deposit(depositAmount);

        vm.prank(beneficiary);
        vm.expectRevert("Cliff not reached");
        vestingvault.claim();
    }

    function testRevokeVesting() public {
        uint256 depositAmount = 100_000 ether;

        vm.prank(owner);
        vestingVault.deposit(depositAmount);

        vm.warp(block.timestamp + vestingDuration / 2);

        uint256 vested = vestingVault.claimableAmount();
        uint256 unvested = depositAmount - vested;

        vm.prank(owner);
        vestingVault.revoke();

        assertEq(vestingVault.totalCLaimed(), 0);
        assertEq(token.balanceOf(owner), unvested);
        assertEq(vestingVault.claimableAmount(), 0);
    }

    function testCannotRevokeTwice() public {
        uint256 depositAmount = 100_000 ether;

        vm.prank(owner);
        vestingVault.deposit(depositAmount);

        vm.prank(owner);
        vestingVault.revoke();

        vm.prank(owner);
        vm.expectRevoke("Already revoked");
        vestingVault.revoke();
    }

    function testClaimableAmount() public {
        uint256 depositAmount = 100_000 ether;

        vm.prank(owner);
        vestingVault.deposit(depositAmount);

        vm.warp(block.timestamp + vestingDuration / 2);

        uint256 claimable = vestVault.claimableAmount();
        assertEq(claimable, depositAmount / 2);
    }
}
