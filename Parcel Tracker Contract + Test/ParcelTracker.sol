//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


contract ParcelTracker {
    struct Parcel {
        uint256 id;
        address recipient;
        DeliveryStatus status;
    }

    enum DeliveryStatus {
        Pending,
        Shipped,
        InTransit,
        Delivered,
        Cancelled
    }

    mapping(uint256 => Parcel) public parcels;

    uint256 public parcelCount;
    address public owner;

    event ParcelAdded(uint256 id, address recipient);
    event StatusUpdated(uint256 id, DeliveryStatus newStatus);

    constructor() {
        owner = msg.sender;
        parcelCount = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function addParcel(address _recipient) public onlyOwner {
        parcelCount ++;

        Parcel memory newParcel = Parcel(parcelCount, _recipient, DeliveryStatus.Pending);
        parcels[parcelCount] = newParcel;

        emit ParcelAdded(parcelCount, _recipient);
    }

    function updateStatus(uint256 _id, DeliveryStatus newStatus) public onlyOwner {
        require(parcels[_id].status != newStatus, "Cannot update to same status");

        parcels[_id].status = newStatus;

        emit StatusUpdated(_id, newStatus);
    }

    function getStatus(uint256 id) public view returns (Parcel memory) {
        return parcels[id];
    }
}