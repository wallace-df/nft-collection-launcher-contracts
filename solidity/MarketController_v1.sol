// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MarketController_v1 {
  address public ownerAddress;

  event ItemListed(address collectionAddress, uint256 tokenId, address sellerAddress, uint256 price);
  event ItemUnlisted(address collectionAddress, uint256 tokenId);
  event ItemSold(address collectionAddress, uint256 tokenId, address buyerAddress, uint256 price);

  event OfferPlaced(uint256 offerId, address collectionAddress, uint256 tokenId, address makerAddress, uint256 amount);
  event OfferUpdated(uint256 offerId, uint256 amount);
  event OfferCanceled(uint256 offerId);
  event OfferAccepted(uint256 offerId);

  struct Listing {
    uint256 nonce;
    address sellerAddress;
    uint256 price;
  }

  struct Offer {
    uint256 offerId;
    address collectionAddress;
    uint256 tokenId;
    uint256 listingNonce;
    address makerAddress;
    uint256 amount;
  }

  uint256 private _lastListingNonce = 0;
  uint256 private _lastOfferId = 0;

  // Collection address => tokenId => Listing
  mapping(address => mapping(uint256 => Listing)) private _listings;

  // Offer id => Offer
  mapping(uint256 => Offer) private _offers;

  // User address => Collection address => tokenId => Offer Id
  mapping(address => mapping(address => mapping(uint256 => uint256))) private _userOffersIds;

  constructor() {
    ownerAddress = msg.sender;
  }

  modifier onlyOwner() {
    require (msg.sender == ownerAddress, "Ownable: caller is not the owner");
    _;
  }

  function listItem(address _collectionAddress, uint256 _tokenId, uint256 _price) external {
    Listing storage listing = _listings[_collectionAddress][_tokenId];
    require (listing.nonce == 0, "Item already listed");
    require (_price > 0, "Invalid price");

    IERC721 nftCollection = IERC721(_collectionAddress);
    require (nftCollection.ownerOf(_tokenId) == msg.sender, "User does not own this NFT");
    nftCollection.transferFrom(msg.sender, address(this), _tokenId);

    _lastListingNonce++;

    listing.nonce = _lastListingNonce;
    listing.sellerAddress = msg.sender;
    listing.price = _price;

    emit ItemListed(_collectionAddress, _tokenId, msg.sender, _price);
  }

  function unlistItem(address _collectionAddress, uint256 _tokenId) external {
    Listing storage listing = _listings[_collectionAddress][_tokenId];
    require (listing.nonce > 0, "Listing not available");
    require (listing.sellerAddress == msg.sender, "Caller is not the seller");

    IERC721(_collectionAddress).transferFrom(address(this), listing.sellerAddress, _tokenId);

    delete _listings[_collectionAddress][_tokenId];
    emit ItemUnlisted(_collectionAddress, _tokenId);
  }

  function buyItem(address _collectionAddress, uint256 _tokenId, uint256 _amount) external {
    Listing storage listing = _listings[_collectionAddress][_tokenId];
    require (listing.nonce > 0, "Listing not available");
    require (listing.sellerAddress != msg.sender, "Caller cannot be the NFT seller");

    uint256 price = listing.price;
    require (_amount == price, "Incorrect amount");

    // TODO: take fee and transfer net amount to NFT seller.
    // ...

    IERC721(_collectionAddress).transferFrom(address(this), msg.sender, _tokenId);

    delete _listings[_collectionAddress][_tokenId];
    emit ItemSold(_collectionAddress, _tokenId, msg.sender, price);
  }

  function placeOffer(address _collectionAddress, uint256 _tokenId, uint256 _amount) external {
    Listing storage listing = _listings[_collectionAddress][_tokenId];
    require (listing.nonce > 0, "Item is not listed");
    require (_amount > 0, "Invalid amount");
    require (_amount < listing.price, "Offer amount should be lower than the listing price");
    require (listing.sellerAddress != msg.sender, "Offer maker cannot be the NFT seller");
    
    uint256 userOfferId = _userOffersIds[msg.sender][_collectionAddress][_tokenId];
    Offer storage offer = _offers[userOfferId];
    if (offer.offerId > 0 && offer.listingNonce == listing.nonce) {
      offer.amount = _amount;
      emit OfferUpdated(offer.offerId , _amount);
      return;
    }

    _lastOfferId++;
    _offers[_lastOfferId] = Offer(_lastOfferId, _collectionAddress, _tokenId, listing.nonce, msg.sender, _amount);
    _userOffersIds[msg.sender][_collectionAddress][_tokenId] = _lastOfferId;

    emit OfferPlaced(_lastOfferId, _collectionAddress, _tokenId, msg.sender, _amount);
  }

  function cancelOffer(uint256 _offerId) external {
    Offer storage offer = _offers[_offerId];
    require (offer.offerId > 0, "Offer not available");
    require (offer.makerAddress == msg.sender, "Caller is not the offer maker");

    Listing storage listing = _listings[offer.collectionAddress][offer.tokenId];
    require (listing.nonce > 0, "Offer is no longer available");
    require (offer.listingNonce == listing.nonce, "Offer is no longer available");

    delete _userOffersIds[msg.sender][offer.collectionAddress][offer.tokenId];
    delete _offers[_offerId];
    emit OfferCanceled(_offerId);
  }

  function acceptOffer(uint256 _offerId) external {
    Offer storage offer = _offers[_offerId];
    require (offer.offerId > 0, "Offer not available");
    require (offer.makerAddress != msg.sender, "Caller cannot be the offer maker");

    Listing storage listing = _listings[offer.collectionAddress][offer.tokenId];
    require (listing.nonce > 0, "Offer is no longer available");
    require (offer.listingNonce == listing.nonce, "Offer is no longer available");

    // TODO: take fee and transfer net amount to NFT seller.
    // ...

    IERC721(offer.collectionAddress).transferFrom(address(this), offer.makerAddress, offer.tokenId);

    emit OfferAccepted(_offerId);    
    emit ItemSold(offer.collectionAddress, offer.tokenId, offer.makerAddress, offer.amount);

    delete _listings[offer.collectionAddress][offer.tokenId];
    delete _userOffersIds[offer.makerAddress][offer.collectionAddress][offer.tokenId];
    delete _offers[_offerId];
  }

  // TODO: add method for contract owner to withdraw fees.
}
