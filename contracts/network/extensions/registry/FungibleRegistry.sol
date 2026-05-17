// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import "../../../token/core/NodeToken.sol";
import "../../../token/core/DiamondCutFacet.sol";

import "hardhat/console.sol";

contract FungibleFactory {

	fallback() external payable {
    console.log("----- fallback:", msg.value);
  }

	receive() external payable {
		console.log("----- receive:", msg.value);
	}

	/********************************************************************************************************/
	/****************************************** Facets Registry *********************************************/
	/********************************************************************************************************/
	string[] facetTypes;

	mapping(string => string[]) facetVersions;

	mapping(string => mapping(string => address)) facetsRegistry;

	function getFacetTypes() external view returns(string[] memory) {
		return facetTypes;
	}

	function getFacetAddress(string calldata facetType, string calldata facetVersion) external view returns(address) {
		return facetsRegistry[facetType][facetVersion];
	}

	function setFacetVersion(string calldata facetType, string calldata facetVersion, address facetAddress) external {
		require(facetsRegistry[facetType][facetVersion] == address(0), "ERRW_INVA_ADD");

		if(facetVersions[facetType].length == 0)
			facetTypes.push(facetType);

		facetVersions[facetType].push(facetVersion);

		facetsRegistry[facetType][facetVersion] = facetAddress;
	}

	struct FacetVersion { 
		string facetVersion;
		address facetAddress;
	}

	function getFacetVersions(string calldata facetType) external view returns (FacetVersion[] memory) {
		uint arrayLength = facetVersions[facetType].length;
		FacetVersion[] memory response = new FacetVersion[](arrayLength);

		for (uint i = 0; i < arrayLength; i++) {

			response[i] = FacetVersion({
											facetVersion: facetVersions[facetType][i],
											facetAddress: facetsRegistry[facetType][facetVersions[facetType][i]]
										});

		}

		return response;
	}

	/********************************************************************************************************/
	/*************************************************** Fungibles ******************************************/
	/********************************************************************************************************/
	mapping(address => string[]) fungiblesByAccount;

	function getFungibles() external view returns(string[] memory) {
		return fungiblesByAccount[msg.sender];
	}

	function getFungiblesByAddress(address crytocommodityOwner) external view returns(string[] memory) {
		return fungiblesByAccount[crytocommodityOwner];
	}

	mapping(string => address) fungibles;

	/*function createFungible(string calldata fungibleName) external {
		require(fungibles[fungibleName] == address(0), 'Existing fungible');

		address diamondCutFacetAddress = facetsRegistry['DiamondCutFacet']['1.0'];
		Node diamond = new Diamond(diamondCutFacetAddress);

		fungiblesByAccount[msg.sender].push(fungibleName);
		fungibles[fungibleName] = address(diamond);
	}*/

	function getFungible(string calldata fungibleName) external view returns(address) {
		return fungibles[fungibleName];
	}

}
