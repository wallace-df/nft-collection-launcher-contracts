// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface INFTCollection is IERC721 {
  function contractURI() external view returns (string memory);
  function currentTokenSupply() external view returns (uint256);
  function maxTokenSupply() external view returns (uint256);
  function mintPrice() external view returns (uint256);
  function mint() external returns (uint256);
}

contract NFTBaseCollection is ERC721, INFTCollection {

  string public override contractURI;
  uint256 public override currentTokenSupply;
  uint256 public override maxTokenSupply;
  uint256 public override mintPrice;

  string private baseTokenURI;

  constructor(string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURI, uint256 _maxTokenSupply, uint256 _mintPrice) ERC721(_name, _symbol) {
    contractURI = _contractURI;
    baseTokenURI = _baseTokenURI;
    maxTokenSupply = _maxTokenSupply;
    mintPrice = _mintPrice;
  }

  function mint() public override returns (uint256) {
    require (currentTokenSupply < maxTokenSupply, "Max supply reached.");

    currentTokenSupply++;
    super._mint(msg.sender, currentTokenSupply); 
    return currentTokenSupply;
  }
 
  function tokenURI(uint256 _tokenId) public view override (ERC721) returns (string memory) {
    require(super._exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    uint256 temp = _tokenId;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    temp = _tokenId;
    while (temp != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(temp % 10)));
        temp /= 10;
    }
    return string(abi.encodePacked(baseTokenURI, string(buffer)));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(INFTCollection).interfaceId || super.supportsInterface(interfaceId);
  }

}

contract NFTCollectionLauncher {

  event NFTCollectionLaunched(address collectionAddress, string collectionName);

  function launchCollection(string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURI, uint256 _maxTokenSupply, uint256 _mintPrice) external {
    NFTBaseCollection collection = new NFTBaseCollection(_name, _symbol, _contractURI, _baseTokenURI, _maxTokenSupply, _mintPrice);
    emit NFTCollectionLaunched(address(collection), _name);
  }

}