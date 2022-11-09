# RadioStar ERC-1155 Implementation

Dappcamp4 Team Project.

## Setup

### Foundry

`forge install foundry-rs/forge-std openzeppelin/openzeppelin-contracts@v4.7.0 Brechtpd/base64 --no-commit`

## Run Tests

`forge test`

## Useful References

- [Getting Started With Forge](https://w.mirror.xyz/mOUlpgkWA178HNUW7xR20TdbGRV6dMid7uChqxf9Z58)
- [OpenZeppelin ERC 1155](https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155)
- [EIP-1155: Multi Token Standard](https://eips.ethereum.org/EIPS/eip-1155) See "Minting/creating and burning/destroying rules"

## Smart Contract deployment

1. Deploy Contract and Verify

```
forge create --rpc-url <your_rpc_url> --constructor-args "" --private-key <your_private_key> src/RadioStar.sol:RadioStar --etherscan-api-key <your_etherscan_api_key>  --verify
```

2. Call createRadioStar()

```
cast send <contract_address> "createRadioStar(uint256,uint256)" 10 10000000 --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Deployed Versions

- 1st version 08/11/2022: https://goerli.etherscan.io/address/0x5ad62406581f849796fa4a53a1316fbe49f0fcfe
