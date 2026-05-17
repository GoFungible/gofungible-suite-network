// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import "../../../token/core/INodeToken.sol";

contract ValidatorNode {
    struct Validation {
        uint256 chainId;
        uint256 blockNumber;
        bytes32 blockHash;
        uint256 timestamp;
        bool isValid;
    }
    
    struct StakeInfo {
        uint256 amount;
        uint256 lockedUntil;
    }
    
    mapping(uint256 => mapping(uint256 => Validation)) public validations;
    mapping(uint256 => bool) public supportedChains;
    mapping(address => StakeInfo) public stakes;
    
    address public owner;
    uint256 public totalStake;
    uint256 public slashingPercentage = 10; // 10% slashing for malicious behavior
    
    event BlockValidated(uint256 indexed chainId, uint256 indexed blockNumber, bool isValid);
    event StakeDeposited(address indexed validator, uint256 amount);
    event StakeWithdrawn(address indexed validator, uint256 amount);
    event ValidatorSlashed(address indexed validator, uint256 amount, string reason);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function addSupportedChain(uint256 chainId) external onlyOwner {
        supportedChains[chainId] = true;
    }
    
    function removeSupportedChain(uint256 chainId) external onlyOwner {
        supportedChains[chainId] = false;
    }
    
    function depositStake() external payable {
        require(msg.value > 0, "Stake must be positive");
        
        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].lockedUntil = block.timestamp + 30 days;
        totalStake += msg.value;
        
        emit StakeDeposited(msg.sender, msg.value);
    }
    
    function withdrawStake(uint256 amount) external {
        require(stakes[msg.sender].amount >= amount, "Insufficient stake");
        require(block.timestamp >= stakes[msg.sender].lockedUntil, "Stake still locked");
        
        stakes[msg.sender].amount -= amount;
        totalStake -= amount;
        
        payable(msg.sender).transfer(amount);
        
        emit StakeWithdrawn(msg.sender, amount);
    }
    
    /*function validateBlock(
        uint256 chainId,
        uint256 blockNumber,
        address nodeContract
    ) external returns (bool) {
        require(supportedChains[chainId], "Chain not supported");
        require(stakes[msg.sender].amount > 0, "Must have stake to validate");
        
        INodeToken node = INodeToken(nodeContract);
        
        // Verify block integrity
        bool isValid = node.verifyBlock(blockNumber);
        
        // Get block hash
        (, , , , , , , bytes32[] memory txHashes) = node.getBlock(blockNumber);
        bytes32 blockHash = keccak256(abi.encodePacked(blockNumber, txHashes));
        
        // Store validation
        validations[chainId][blockNumber] = Validation({
            chainId: chainId,
            blockNumber: blockNumber,
            blockHash: blockHash,
            timestamp: block.timestamp,
            isValid: isValid
        });
        
        emit BlockValidated(chainId, blockNumber, isValid);
        
        return isValid;
    }*/
    
    function signTransaction(
        bytes32 txHash,
        uint256 targetChainId
    ) external view returns (bytes memory) {
        require(supportedChains[targetChainId], "Target chain not supported");
        require(stakes[msg.sender].amount > 0, "Must have stake to sign");
        
        // In production, this would generate a cryptographic signature
        // For demo, we'll return a simple encoded signature
        return abi.encodePacked(txHash, targetChainId, msg.sender, block.timestamp);
    }
    
    function slashValidator(address validator, uint256 amount, string calldata reason) external onlyOwner {
        require(stakes[validator].amount >= amount, "Insufficient stake to slash");
        
        uint256 slashedAmount = (amount * slashingPercentage) / 100;
        stakes[validator].amount -= slashedAmount;
        totalStake -= slashedAmount;
        
        emit ValidatorSlashed(validator, slashedAmount, reason);
    }
    
    function getValidatorInfo(address validator) external view returns (
        uint256 stake,
        uint256 lockedUntil,
        uint256 validationCount
    ) {
        StakeInfo storage s = stakes[validator];
        
        // Count validations by this validator
        uint256 count = 0;
        // Simplified - would need to track in production
        
        return (s.amount, s.lockedUntil, count);
    }
    
    function getValidation(uint256 chainId, uint256 blockNumber) external view returns (
        uint256 _chainId,
        uint256 _blockNumber,
        bytes32 blockHash,
        uint256 timestamp,
        bool isValid
    ) {
        Validation storage v = validations[chainId][blockNumber];
        return (
            v.chainId,
            v.blockNumber,
            v.blockHash,
            v.timestamp,
            v.isValid
        );
    }
    
    function setSlashingPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Percentage cannot exceed 100");
        slashingPercentage = percentage;
    }
}