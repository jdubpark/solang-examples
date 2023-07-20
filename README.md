# ERC-20 on Solana

Write Solidity ERC-20 on Solana using Solang!

Example Account & Transactions on Devnet: 
- [Contract](https://solscan.io/account/CR3JGL7NVpm9Y7ohEHw92x3SPseMvPwgx1oviu5ixJKv?cluster=devnet)
- [Mint](https://solscan.io/tx/37suTLk2enadoFsRpc43CbUWkNDty7sof9BF4HhJKoyhLok3rWBytQbRrLErQwrhAxcviyCbAKJGrHAbzYeLDfFS?cluster=devnet)
- [Transfer](https://solscan.io/tx/573tJ5z1mR58NSvEGNT58pRno9ZyVkyFgoPP9dVUdf6BAMQvxepSKEUjLz2k6jDh1pJ38Fj91xBNJ52T8hubpohA?cluster=devnet)

## Instructions

First, install solana CLI and solang. 
```bash
# solana
sh -c "$(curl -sSfL https://release.solana.com/v1.16.4/install)"

# solang
brew install hyperledger/solang/solang
```

Then, run the solana-test-validator
```bash
solana-test-validator -r
```

Then, deploy the ERC-20 contract on Solana using Solang.
```bash
bash contracts/examples/token/deploy.sh  
```

Then, run the ERC-20 tests!
```bash
cd tests
yarn install
yarn test:basic_token
```

## Code
Check out `contracts/examples/token/BasicToken.sol` and `contracts/libarires/token/ERC20Like.sol`.

## Disclaimer
For test only. Not for production! Scripts are tested on Macbook.
