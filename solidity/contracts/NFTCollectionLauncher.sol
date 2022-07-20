// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./NFTBaseCollection.sol";

contract NFTCollectionLauncher {

  event NFTCollectionLaunched(address collectionAddress, string collectionName);

  function launchCollection(string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURI, uint256 _maxTokenSupply, uint256 _mintPrice) external {
    NFTBaseCollection collection = new NFTBaseCollection(_name, _symbol, _contractURI, _baseTokenURI, _maxTokenSupply, _mintPrice);
    emit NFTCollectionLaunched(address(collection), _name);
  }

}