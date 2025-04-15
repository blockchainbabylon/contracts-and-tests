//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract DecentralizedGiftRegistry {
    address public owner;
    uint256 public registryIdCounter;
    uint256 public globalGiftIdCounter;

    struct Gift {
        uint256 id;
        string name;
        string description;
        uint256 price;
        address payable reservedBy;
        bool purchased;
        uint256 registryId;
    }

    mapping(uint256 => Gift) public gifts;
    mapping(address => uint256[]) public userRegistries;
    mapping(uint256 => address) public registryOwners;
    mapping(uint256 => uint256[]) public registryGifts;

    event RegistryCreated(address indexed creator, uint256 registryId);
    event GiftAdded(uint256 indexed registryId, uint256 giftId, string name);
    event GiftReserved(uint256 indexed registryId, uint256 giftId, address indexed reserver);
    event GiftPurchased(uint256 indexed registryId, uint256 giftId, address indexed purchaser);
    event GiftRemoved(uint256 indexed registryId, uint256 giftId);

    modifier onlyRegistryOwner(uint256 _registryId) {
        require(registryOwners[_registryId] == msg.sender, "Only the registry owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        registryIdCounter = 1;
        globalGiftIdCounter = 1;
    }

    function createRegistry() public returns (uint256) {
        uint256 newRegistryId = registryIdCounter++;
        registryOwners[newRegistryId] = msg.sender;
        userRegistries[msg.sender].push(newRegistryId);
        emit RegistryCreated(msg.sender, newRegistryId);
        return newRegistryId;
    }

    function addGift(
        uint256 _registryId,
        string memory _name,
        string memory _description,
        uint256 _price
    ) public onlyRegistryOwner(_registryId) {
        uint256 newGiftId = globalGiftIdCounter++;
        gifts[newGiftId] = Gift({
            id: newGiftId,
            name: _name,
            description: _description,
            price: _price,
            reservedBy: payable(address(0)),
            purchased: false,
            registryId: _registryId
        });
        registryGifts[_registryId].push(newGiftId);
        emit GiftAdded(_registryId, newGiftId, _name);
    }

    function reserveGift(uint256 _giftId) public {
        require(gifts[_giftId].id != 0, "Gift not found");
        require(gifts[_giftId].reservedBy == address(0), "Gift already reserved");
        require(!gifts[_giftId].purchased, "Gift already purchased");
        gifts[_giftId].reservedBy = payable(msg.sender);
        emit GiftReserved(gifts[_giftId].registryId, _giftId, msg.sender);
    }

    function purchaseGift(uint256 _giftId) public payable {
        require(gifts[_giftId].id != 0, "Gift not found");
        require(gifts[_giftId].reservedBy != address(0), "Gift must be reserved before purchase");
        require(!gifts[_giftId].purchased, "Gift already purchased");
        require(msg.value >= gifts[_giftId].price, "Insufficient funds sent");

        gifts[_giftId].purchased = true;
        address payable recipient = gifts[_giftId].reservedBy;
        recipient.transfer(msg.value);
        emit GiftPurchased(gifts[_giftId].registryId, _giftId, msg.sender);
    }

    function getRegistryGifts(uint256 _registryId) public view returns (Gift[] memory) {
        uint256[] memory giftIds = registryGifts[_registryId];
        Gift[] memory result = new Gift[](giftIds.length);
        for (uint256 i = 0; i < giftIds.length; i++) {
            result[i] = gifts[giftIds[i]];
        }
        return result;
    }

    function getMyRegistries() public view returns (uint256[] memory) {
        return userRegistries[msg.sender];
    }

    function getGiftDetails(uint256 _giftId) public view returns (Gift memory) {
        return gifts[_giftId];
    }

    function removeGift(uint256 _registryId, uint256 _giftId) public onlyRegistryOwner(_registryId) {
        require(gifts[_giftId].id != 0 && gifts[_giftId].registryId == _registryId, "Gift not found in this registry");

        uint256[] storage giftIdArray = registryGifts[_registryId];
        for (uint256 i = 0; i < giftIdArray.length; i++) {
            if (giftIdArray[i] == _giftId) {
                giftIdArray[i] = giftIdArray[giftIdArray.length - 1];
                giftIdArray.pop();
                break;
            }
        }

        delete gifts[_giftId];
        emit GiftRemoved(_registryId, _giftId);
    }
}
