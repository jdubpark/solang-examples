# ERC-20 on Solana

Write Solidity ERC-20 on Solana using Solang!

## Instructions

First, install solana CLI and solang. Navigate to the root folder now.

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
