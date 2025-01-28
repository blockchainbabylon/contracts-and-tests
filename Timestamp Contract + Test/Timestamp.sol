//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimestampTracker {
    struct Entry {
        string data;
        uint256 timestamp;
    }

    mapping(address => Entry) public entries;

    event EntryCreated(address indexed user, string data, uint256 timestamp);

    function createEntry(string calldata _data) public {
        require(bytes(_data).length > 0, "Data cannot be empty");
        require(entries[msg.sender].timestamp == 0, "Entry already exists");

        entries[msg.sender] = Entry({
            data: _data,
            timestamp: block.timestamp
        });

        emit EntryCreated(msg.sender, _data, block.timestamp);
    }

    function getEntryAge(address _user) public view returns (uint256) {
        require(entries[_user].timestamp > 0, "No entry for this user");

        return block.timestamp - entries[_user].timestamp;
    }
}