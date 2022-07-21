%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import deploy
from starkware.cairo.common.uint256 import Uint256

# Define a storage variable for the salt.
@storage_var
func salt() -> (value : felt):
end

# Define a storage variable for the class hash of NFTBaseCollection contract.
@storage_var
func collectionClassHash() -> (value : felt):
end

# An event emitted whenever deploy_ownable_contract() is called.
@event
func NFTCollectionLauncher(address:felt, name: felt):
end

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
    }(_collectionClassHash : felt):
    collectionClassHash.write(value=_collectionClassHash)
    return ()
end

@external
func launchCollection{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
    } (
        _name: felt,
        _symbol: felt,
        _contractURI_len: felt,
        _contractURI: felt*,
        _baseTokenURI_len: felt,
        _baseTokenURI: felt*,
        _maxTokenSupply: Uint256,
        _mintPrice: Uint256,
    ):
    alloc_locals
   

    let (calldata : felt*) = alloc()
    assert calldata[0] = _name
    assert calldata[1] = _symbol

    assert calldata[2] = _contractURI_len
    memcpy(calldata+3, _contractURI, _contractURI_len)

    assert calldata[3+_contractURI_len] = _baseTokenURI_len
    memcpy(calldata+4+_contractURI_len, _baseTokenURI, _baseTokenURI_len)

    assert calldata[4+_contractURI_len+_baseTokenURI_len] = _maxTokenSupply.low
    assert calldata[5+_contractURI_len+_baseTokenURI_len] = _maxTokenSupply.high

    assert calldata[6+_contractURI_len+_baseTokenURI_len] = _mintPrice.low
    assert calldata[7+_contractURI_len+_baseTokenURI_len] = _mintPrice.high
	
    let (currentSalt) = salt.read()
    let (classHash) = collectionClassHash.read()
    let (collectionAddress) = deploy(
        class_hash=classHash,
        contract_address_salt=currentSalt,
        constructor_calldata_size=8 +_contractURI_len + _baseTokenURI_len,
        constructor_calldata=calldata,
        deploy_from_zero=FALSE
    )
    salt.write(value=currentSalt + 1)

    NFTCollectionLauncher.emit(collectionAddress, _name)
    return ()
end
