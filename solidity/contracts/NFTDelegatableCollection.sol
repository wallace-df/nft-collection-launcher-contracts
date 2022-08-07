// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./INFTDelegatableCollection.sol";
import "./NFTBaseCollection.sol";

contract NFTDelegatableCollection is NFTBaseCollection, INFTDelegatableCollection {

  struct UserInfo {
    address user;
    uint256 expires;
  }

  mapping(uint256 => UserInfo) internal _users;

  constructor(string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURI, uint256 _maxTokenSupply, uint256 _mintPrice) NFTBaseCollection(_name, _symbol, _contractURI, _baseTokenURI, _maxTokenSupply, _mintPrice) {
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(NFTBaseCollection, IERC165) returns(bool) {
    return interfaceId == type(INFTDelegatableCollection).interfaceId || super.supportsInterface(interfaceId);
  }

  function setUser(uint256 tokenId, address user, uint256 expires) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
    UserInfo storage info = _users[tokenId];
    info.user = user;
    info.expires = expires;
    emit UpdateUser(tokenId, user, expires);
  }

  function userOf(uint256 tokenId) public view virtual returns(address) {
    if (uint256(_users[tokenId].expires) >= block.timestamp) {
      return _users[tokenId].user;
    } else {
      return address(0);
    }
  }

  function userExpires(uint256 tokenId) public view virtual returns(uint256) {
    return _users[tokenId].expires;
  }
}
