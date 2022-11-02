// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ERC721_IWallets {
    function signerAddress() view external returns(address);
    function withdrawerAddress() view external returns(address);
}

contract ERC721_v1 is IERC721 {
    using Address for address;
    using ECDSA for bytes32;
    using Strings for uint256;

    // Control variables
    bool internal _initialized;

    // Wallets
    ERC721_IWallets _wallets;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _baseURI;

    // Max token supply
    uint256 private _maxTokenSupply;

    // Current token supply
    uint256 private _currentTokenSupply;

    // Token ids
    uint256[] private _tokenIds;
    uint256 private index;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to owner address
    mapping(string => mapping(address => uint256)) private _phaseMintedTokens;

    // Hash mapping
    mapping(bytes32 => bool) private _usedHashes;

    constructor(string memory name_, string memory symbol_, string memory baseURI_, uint256 maxTokenSupply_, ERC721_IWallets wallets_) {
        _initialize(name_, symbol_, baseURI_, maxTokenSupply_, wallets_);
    }

   function initialize(string memory name_, string memory symbol_, string memory baseURI_, uint256 maxTokenSupply_, ERC721_IWallets wallets_) external {
        _initialize(name_, symbol_, baseURI_, maxTokenSupply_, wallets_);
    }

    function _initialize(string memory name_, string memory symbol_, string memory baseURI_, uint256 maxTokenSupply_, ERC721_IWallets wallets_) internal {
        require(!_initialized, "Already initialized.");
        _initialized = true;
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _maxTokenSupply = maxTokenSupply_;
        _wallets = wallets_;
        _tokenIds = new uint256[](_maxTokenSupply);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = this.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not token owner nor approved for all");

        _approve(to, tokenId);
    }

    function mint(string memory phaseId, uint256 phaseLimit, uint256 blockLimit, uint256 random, uint256 price, uint256 maxTokensPerWallet, bytes memory signature) external payable {
        require(bytes(phaseId).length > 0, "Invalid phase.");
        require(blockLimit <= block.number, "Timed out.");
        require(phaseLimit <= _maxTokenSupply, "Invalid phase limit.");
        require(_currentTokenSupply < phaseLimit, "Phase limit reached.");
        require(price > 0, "Invalid price.");
        require(msg.value == price, "Invalid amount.");
        require(msg.sender == tx.origin, "Contract mints not allowed.");

        if (maxTokensPerWallet > 0) {
            require (_phaseMintedTokens[phaseId][msg.sender] < maxTokensPerWallet, "Max tokens per wallet exceeded.");
        }

        address signer = _wallets.signerAddress();
        bytes32 messageHash = _hashParams(msg.sender, phaseId, phaseLimit, blockLimit, random, price, maxTokensPerWallet, address(this));
        uint256 tokenId = _pickRandomUniqueId(random);

        require(messageHash.recover(signature) == signer, "Hash mismatch.");
        require(!_usedHashes[messageHash], "Hash already used.");

        _usedHashes[messageHash] = true;
        _currentTokenSupply++;
        _mint(msg.sender, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = this.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(this.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(this.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _hashParams(address sender, string memory phaseId, uint256 phaseLimit, uint256 blockLimit, uint256 random, uint256 price, uint256 maxTokensPerWallet, address contractAddress) internal pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, phaseId, phaseLimit, blockLimit, random, price, maxTokensPerWallet, contractAddress))
          ));    
          return hash;
    }

    function _pickRandomUniqueId(uint256 random) internal returns (uint256) {
        uint256 len = _tokenIds.length - index++;
        require(len > 0, "no ids left");
        uint256 randomIndex = random % len;
        uint256 id = _tokenIds[randomIndex] != 0 ? _tokenIds[randomIndex] : randomIndex;
        _tokenIds[randomIndex] = uint256(_tokenIds[len - 1] == 0 ? len - 1 : _tokenIds[len - 1]);
        _tokenIds[len - 1] = 0;

        return id;
    }
}
  
contract ERC721_v1_Deployer is ERC721_IWallets {
    ERC721_v1 private _base;
    address private _owner;
    address private _signer;
    address private _withdrawer;
 
    constructor() {
        _base = _deploy("NFT", "NFT", "", 0);
        _owner = msg.sender;
        _signer = msg.sender;
        _withdrawer = msg.sender;
    }

    function signerAddress() view external override returns(address) {
        return _signer;
    }

    function withdrawerAddress() view external override returns(address) {
        return _withdrawer;        
    }

    function setSigner(address signer_) external {
        require(msg.sender == _owner, "Not owner.");
        _signer = signer_;
    }

    function setWithdrawer(address withdrawer_) external {
        require(msg.sender == _owner, "Not owner.");
        _withdrawer = withdrawer_;
    }

    function deploy(string memory _name, string memory _symbol, string memory _baseTokenURI, uint256 _maxTokenSupply) public returns (ERC721_v1) {
        return _deploy(_name, _symbol, _baseTokenURI, _maxTokenSupply);
    }

    function clone(string memory _name, string memory _symbol, string memory _baseTokenURI, uint256 _maxTokenSupply) public returns (ERC721_v1) {
        address implementation = address(_base);
        address instanceAddress;
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(
                0x00,
                or(
                    shr(0xe8, shl(0x60, implementation)),
                    0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
                )
            )
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(
                0x20,
                or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3)
            )
            instanceAddress := create(0, 0x09, 0x37)
        }
        require (instanceAddress != address(0), "ERC1167: create failed");
        ERC721_v1 instance = ERC721_v1(instanceAddress);
        instance.initialize(_name, _symbol, _baseTokenURI, _maxTokenSupply, this);
        return instance;
    }

    function _deploy(string memory _name, string memory _symbol, string memory _baseTokenURI, uint256 _maxTokenSupply) public returns (ERC721_v1) {
        return new ERC721_v1(_name, _symbol, _baseTokenURI, _maxTokenSupply, this);
    }

} 
