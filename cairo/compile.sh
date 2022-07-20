mkdir -p artifacts/compiled
mkdir -p artifacts/abis
cd contracts
starknet-compile NFTBaseCollection.cairo \
    --output ../artifacts/compiled/NFTBaseCollection.json \
    --abi ../artifacts/abis/NFTBaseCollection.json

echo "Done!"