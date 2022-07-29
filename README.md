# NFT Launcher Contracts
Smart contracts (minter) for the NFT Collection Launcher.

---

NFT Launcher is a dApp that provides an interface for:

- Processing, bundling and uploading NFT assets (.json, .png) to IPFS via NFTStorage API (https://nft.storage/).
- Automatically deploying the NFT minter contracts to the following networks:
  - StarkNet (testnet) - https://starknet.io/
  - zkSync (testnet) -  https://zksync.io/

---

## Cairo

### Install dependencies

Refer to https://starknet.io/docs/quickstart.html#quickstart

### Compile contracts


```shell
cd cairo
chmod +x compile_cairo_contracts.sh
./compile_cairo_contracts.sh
```

### Deploy on the StarkNet network

```shell
cd cairo
chmod +x deploy_cairo_contracts.sh
./deploy_cairo_contracts.sh
```

## Solidity

### Install dependencies

```shell
yarn install
```

### Compile contracts

```shell
yarn hardhat compile
```

### Deploy on the zkSync network

1. Create the *solidity/keys.json* file and set the deployer private wallet:
```json
{  "zkSyncDeployerWallet": "<YOUR_WALLET_PRIVATE_KEY" }
```

2. Deploy:
```shell
yarn hardhat deploy-zksync
```
