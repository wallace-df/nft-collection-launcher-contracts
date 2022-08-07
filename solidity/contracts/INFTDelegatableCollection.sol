// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTDelegatableCollection is IERC721 {
  event UpdateUser(uint256 tokenId, address user, uint256 expires);

  function setUser(uint256 tokenId, address user, uint256 expires) external;
  function userOf(uint256 tokenId) external view returns(address);
  function userExpires(uint256 tokenId) external view returns(uint256);
}