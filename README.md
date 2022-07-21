# NFT Launcher Contracts
Smart contracts for NFT Collection Launcher.

- Cairo:
  - Shell scripts are included to compile and deploy contracts on the StarkNet-testnet network (https://starknet.io/).
- Solidity:
  - Hardhat configuration is included to compile and deploy contracts on the zkSync-testnet network (https://zksync.io/).


## Cairo

### Install dependencies

Refer to https://starknet.io/docs/quickstart.html#quickstart

### Compile contracts

`cd cairo` 
`chmod +x compile_cairo_contracts.sh` 
`./compile_cairo_contracts.sh` 

### Deploy contracts on the StarkNet network

`cd cairo`
`chmod +x deploy_cairo_contracts.sh`
`./deploy_cairo_contracts.sh`

## Solidity

### Install dependencies

`yarn install`

### Compile contracts

`yarn hardhat compile`

### Deploy contracts on the zkSync network

1. Set the deployer private wallet in the "solidity/keys.json" file:
`{  "zkSyncDeployerWallet": "<YOUR_WALLET_PRIVATE_KEY" }`

2. Deploy
`yarn hardhat deploy-zksync`
 
