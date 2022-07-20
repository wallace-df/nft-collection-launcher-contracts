// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTCollection is IERC721 {
  function contractURI() external view returns (string memory);
  function currentTokenSupply() external view returns (uint256);
  function maxTokenSupply() external view returns (uint256);
  function mintPrice() external view returns (uint256);
  function mint() external returns (uint256);
}