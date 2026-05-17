// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INodeToken {
    function createTransaction(address to, uint256 amount) external returns (bytes32);
    function executeCrossChainTransaction(bytes32 txHash, uint256 sourceChainId, bytes[] calldata signatures) external returns (bool);
    function getChainId() external view returns (uint256);
}

contract BridgeRouter {
    struct ChainInfo {
        address nodeContract;
        uint256 lastBlockSynced;
        bool isActive;
        uint256 requiredValidators;
        string name;
    }
    
    struct Transfer {
        bytes32 txHash;
        uint256 fromChain;
        uint256 toChain;
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        TransferStatus status;
    }
    
    enum TransferStatus { Pending, Completed, Failed }
    
    mapping(uint256 => ChainInfo) public chains;
    mapping(bytes32 => Transfer) public transfers;
    mapping(bytes32 => bool) public processedTransactions;
    
    uint256 public totalChains;
    address public owner;
    
    event ChainRegistered(uint256 indexed chainId, address nodeContract, string name);
    event CrossChainTransferInitiated(
        bytes32 indexed txHash,
        uint256 indexed fromChain,
        uint256 indexed toChain,
        address from,
        address to,
        uint256 amount
    );
    event TransferCompleted(bytes32 indexed txHash);
    event TransferFailed(bytes32 indexed txHash, string reason);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function registerChain(
        uint256 chainId,
        address nodeContract,
        string calldata name,
        uint256 requiredValidators
    ) external onlyOwner {
        require(nodeContract != address(0), "Invalid contract address");
        require(chains[chainId].nodeContract == address(0), "Chain already registered");
        
        chains[chainId] = ChainInfo({
            nodeContract: nodeContract,
            lastBlockSynced: 0,
            isActive: true,
            requiredValidators: requiredValidators,
            name: name
        });
        
        totalChains++;
        
        emit ChainRegistered(chainId, nodeContract, name);
    }
    
    function initiateCrossChainTransfer(
        uint256 toChainId,
        address to,
        uint256 amount
    ) external returns (bytes32) {
        ChainInfo storage sourceChain = chains[block.chainid];
        ChainInfo storage targetChain = chains[toChainId];
        
        require(sourceChain.isActive, "Source chain not active");
        require(targetChain.isActive, "Target chain not active");
        
        INodeToken sourceNode = INodeToken(sourceChain.nodeContract);
        
        // Create transaction hash
        bytes32 txHash = keccak256(
            abi.encodePacked(
                msg.sender,
                to,
                amount,
                block.timestamp,
                block.chainid,
                toChainId
            )
        );
        
        require(!processedTransactions[txHash], "Transaction already processed");
        
        // Create transaction on source chain (burns tokens)
        sourceNode.createTransaction(to, amount);
        
        // Store transfer info
        transfers[txHash] = Transfer({
            txHash: txHash,
            fromChain: block.chainid,
            toChain: toChainId,
            from: msg.sender,
            to: to,
            amount: amount,
            timestamp: block.timestamp,
            status: TransferStatus.Pending
        });
        
        processedTransactions[txHash] = true;
        
        emit CrossChainTransferInitiated(txHash, block.chainid, toChainId, msg.sender, to, amount);
        
        return txHash;
    }
    
    function completeCrossChainTransfer(
        bytes32 txHash,
        bytes[] calldata signatures
    ) external returns (bool) {
        Transfer storage transfer = transfers[txHash];
        require(transfer.status == TransferStatus.Pending, "Invalid transfer state");
        
        ChainInfo storage targetChain = chains[transfer.toChain];
        require(targetChain.isActive, "Target chain not active");
        
        INodeToken targetNode = INodeToken(targetChain.nodeContract);
        
        try targetNode.executeCrossChainTransaction(txHash, transfer.fromChain, signatures) {
            transfer.status = TransferStatus.Completed;
            emit TransferCompleted(txHash);
            return true;
        } catch Error(string memory reason) {
            transfer.status = TransferStatus.Failed;
            emit TransferFailed(txHash, reason);
            return false;
        }
    }
    
    function getTransfer(bytes32 txHash) external view returns (
        bytes32 _txHash,
        uint256 fromChain,
        uint256 toChain,
        address from,
        address to,
        uint256 amount,
        uint256 timestamp,
        TransferStatus status
    ) {
        Transfer storage t = transfers[txHash];
        return (
            t.txHash,
            t.fromChain,
            t.toChain,
            t.from,
            t.to,
            t.amount,
            t.timestamp,
            t.status
        );
    }
    
    function getChainInfo(uint256 chainId) external view returns (
        address nodeContract,
        uint256 lastBlockSynced,
        bool isActive,
        uint256 requiredValidators,
        string memory name
    ) {
        ChainInfo storage c = chains[chainId];
        return (
            c.nodeContract,
            c.lastBlockSynced,
            c.isActive,
            c.requiredValidators,
            c.name
        );
    }
    
    function setChainActive(uint256 chainId, bool active) external onlyOwner {
        chains[chainId].isActive = active;
    }
    
    function updateRequiredValidators(uint256 chainId, uint256 required) external onlyOwner {
        require(required > 0, "Must require at least 1");
        chains[chainId].requiredValidators = required;
    }
}