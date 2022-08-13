set -e
output=`starknet declare --network=alpha-goerli --contract ./artifacts/compiled/NFTBaseCollection.json`
contract_hash_class=${output:51:65}
starknet deploy --network=alpha-goerli --contract ./artifacts/compiled/NFTCollectionLauncher.json --inputs  ${contract_hash_class} --no_wallet

output=`starknet declare --network=alpha-goerli --contract ./artifacts/compiled/NFTDelegatableCollection.json`
contract_hash_class=${output:51:65}
starknet deploy --network=alpha-goerli --contract ./artifacts/compiled/NFTCollectionLauncher.json --inputs  ${contract_hash_class} --no_wallet
