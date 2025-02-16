//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/KeccakPractice.sol";

contract KeccakPractice is Test {
    KeccakPractice keccakPractice;
    address submitter = address(0x123);

    function setUp() public {
        keccakPractice = new KeccakPractice();
    }

    function testStoreData() public {
        string memory data = "test data";
        vm.prank(submitter);
        keccakPractice.storeData(data);

        bytes32 dataHash = keccak256(abi.encodePacked(data, submitter, block.timestamp));
        assertTrue(keccakPractice.proofs(dataHash));
    }

    function testStoreDataTwice() public {
        string memory data = "test data";
        vm.prank(submitter);
        keccakPractice.storeData(data);

        vm.expectRevert("Data already exists");
        vm.prank(submitter);
        keccakPractice.storeData(data);
    }

    function testVerifyData() public {
        string memory data = "test data";
        uint256 timestamp = block.timestamp;

        vm.prank(submitter);
        keccakPractice.storeData(data);

        assertTrue(keccakPractice.verifyData(data, submitter, timestamp));
    }

    function testVerifyDataFalse() public {
        string memory data = "test data";
        uint256 timestamp = block.timestamp;

        assertFalse(keccakPractice.verifyData(data, submitter, timestamp));
    }
}