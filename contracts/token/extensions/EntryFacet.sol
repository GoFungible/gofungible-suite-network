// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "./IEntryFacet.sol";

/**
 * @title EntryFacet
 * @dev Example ERC20 token demonstrating _beforeTokenTransfer and _afterTokenTransfer hooks
 */
contract EntryFacet is IEntryFacet {
    

    /**
     * @dev Hook that is called before any transfer of tokens.
     * This includes minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external virtual override {

    }
    
    /**
     * @dev Hook that is called after any transfer of tokens.
     * This includes minting and burning.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external virtual override {

    }
    
}