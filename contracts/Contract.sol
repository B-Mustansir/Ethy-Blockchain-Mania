// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// Import thirdweb contracts
import "@thirdweb-dev/contracts/drop/DropERC1155.sol";
import "@thirdweb-dev/contracts/token/TokenERC20.sol";
import "@thirdweb-dev/contracts/openzeppelin-presets/utils/ERC1155/ERC1155Holder.sol";

// Import OpenZeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyContract is ReentrancyGuard, ERC1155Holder {

    DropERC1155 public immutable toolsCollection; 
    TokenERC20 public immutable mustuCoins;

    constructor (DropERC1155 toolsCollectionAddress, TokenERC20 mustuCoinsAddress){
        toolsCollection = toolsCollectionAddress; 
        mustuCoins = mustuCoinsAddress; 
    }

    struct mapValue {
        bool isData; 
        uint256 value; 
    }

    mapping (address => mapValue) public playerTool;
    mapping (address => mapValue) public playerLastUpdate; 

    function stake(uint256 _tokenId) external nonReentrant {
        
        require(toolsCollection.balanceOf(msg.sender, _tokenId)>=1, "You must have atleast 1 of the tools you are trying to stake"); 

        if(playerTool[msg.sender].isData){
            toolsCollection.safeTransferFrom(address(this), msg.sender, playerTool[msg.sender].value, 1, "Returning your old tool"); 
        }

        uint256 reward = calculateRewards(msg.sender); 
        mustuCoins.transfer(msg.sender, reward); 
        
        toolsCollection.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "Staking your tool"); 

        playerTool[msg.sender].value = _tokenId; 
        playerTool[msg.sender].isData = true; 

        playerLastUpdate[msg.sender].value = block.timestamp; 
        playerLastUpdate[msg.sender].isData = true;

    }

    function calculateRewards(address _player) public view returns (uint256 _rewards) {
        
        if(!playerLastUpdate[_player].isData || !playerTool[_player].isData){
            return 0; 
        }

        uint256 timeDifference = block.timestamp - playerLastUpdate[_player].value; 

        uint256 rewards = timeDifference * 10_000_000_000_000 * (playerTool[_player].value+1);

        return rewards; 
    }

    function withdraw() external nonReentrant{

        require(playerTool[msg.sender].isData, "You do not have a tool to withdraw"); 

        uint256 reward = calculateRewards(msg.sender); 
        mustuCoins.transfer(msg.sender, reward); 
        
        toolsCollection.safeTransferFrom(address(this), msg.sender, playerTool[msg.sender].value, 1, "Returning your tool"); 

        playerTool[msg.sender].isData = false; 

        playerLastUpdate[msg.sender].value = block.timestamp; 
        playerLastUpdate[msg.sender].isData = true;

    }

    function claim() external nonReentrant{

        uint256 reward = calculateRewards(msg.sender); 
        mustuCoins.transfer(msg.sender, reward); 

        playerLastUpdate[msg.sender].value = block.timestamp; 
        playerLastUpdate[msg.sender].isData = true;        

    }

}