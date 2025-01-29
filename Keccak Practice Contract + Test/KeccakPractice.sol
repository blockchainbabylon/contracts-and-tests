//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract KeccakPractice {
    mapping(bytes32 => bool) public proofs;

    event DataStored(bytes32 indexed hash, address indexed submitter);


    //allow anyone to create a hash with a message, their address, and the current time
    function storeData(string memory data) public {
        
        //create local variable to store the hash of provided data
        bytes32 dataHash = keccak256(abi.encodePacked(data, msg.sender, block.timestamp));
        require(!proofs[dataHash], "Data already exists"); //Ensure no same data has already been stored

        proofs[dataHash] = true; 
        
        emit DataStored(dataHash, msg.sender);
    }
    //we want to check if the hash output is the same with the given data
    function verifyData(string memory data, address submitter, uint256 timestamp) public view returns(bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(data, submitter, timestamp));
        return proofs[dataHash]; 
    }
}