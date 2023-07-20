# ERC-20 on Solana

Write Solidity ERC-20 on Solana using Solang!

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
