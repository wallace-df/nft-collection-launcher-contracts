# NFT Launcher Contracts
Smart contracts for NFT Collection Launcher.

- Cairo:
  - Shell scripts are included to compile and deploy contracts on the StarkNet-testnet network (https://starknet.io/).
- Solidity:
  - Hardhat configuration is included to compile and deploy contracts on the zkSync-testnet network (https://zksync.io/).

### Install Cairo dependencies

Refer to https://starknet.io/docs/quickstart.html#quickstart

### Compile Cairo contracts

`./compile_cairo_contracts.sh`

### Deploy Cairo contracts on the StarkNet network

`./deploy_cairo_contracts.sh`


### Install Solidity dependencies

`yarn install`

### Compile Solidity contracts

`yarn hardhat compile`

### Deploy Solidity contracts on the zkSync network

`yarn hardhat deploy`
 