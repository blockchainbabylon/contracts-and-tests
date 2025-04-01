//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contract/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TimeLockedNFTVault is Ownable {
    struct Deposit {
        address nftContract;
        uint256 tokenId;
        uint256 unlockTime;
        address owner;
        uint256 ethReward;
    }

    mapping(address => Deposit[]) public deposits;
    uint256 public rewardPerSecond = 0.00001 ether;

    event NFTDeposited(address indexed user, address indexed nftContract, uint256 tokenId, uint256 unlockTime);
    event NFTWithdrawn(address indexed user, address indexed nftContract, uint256 tokenId, uint256 rewardReceived);

    function depositNFT(address nftContract, uint256 tokenId, uint256 lockDuration) external payable {
        require(lockDuration >= 1 days, "Lock period too short");
        require(msg.value >= 0.01 ether, "Minimum deposit required for staking reward");

        uint256 unlockTime = block.timestamp + lockDuration;
        uint256 reward = lockDuation * rewardPerSecond;

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        deposits[msg.sender].push(Deposit({
            nftContract: nftContract,
            tokenId: tokenId,
            unlockTime: unlockTime,
            owner: msg.sender,
            ethReward: reward
        }));

        emit NFTDeposited(msg.sender, nftSender, tokenId, unlockTime);
    } 

    function withdrawNFT(uint256 index) external {
        require(index < deposits[msg.sender].length, "Invalid index");

        Deposit memory depositData = deposits[msg.sender][index];
        require(block.timestamp >= depositData.unlockTime, "NFT is still locked");

        IERC721(depositData.nftContract).transferFrom(address(this), msg.sender, depositData.tokenId);

        uint256 reward = depositData.ethReward;
        if (reward > 0) {
            payable(msg.sender).transfer(reward);
        }

        deposits[msg.sender][index] = deposits[msg.sender][deposits[msg.sender].length - 1];
        deposits[msg.sender].pop();

        emit NFTWithdrawn(msg.sender, depositData.nftContract, depositData.tokenId, reward);
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardPerSecond = newRate;
    }

    receive() external payable {}

    function withdrawContractFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
