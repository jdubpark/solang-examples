#!/bin/bash

set -e # exit if any error occurs

GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
CONTRACT_DIR="${GIT_ROOT_DIR}/contracts/examples/token"

solang compile --target solana "${CONTRACT_DIR}/BasicToken.sol" -o "${CONTRACT_DIR}/compile" -v

solana program deploy -u l --program-id "${CONTRACT_DIR}/compile/basic-token-keypair.json" "${CONTRACT_DIR}/compile/BasicToken.so"

# copy IDL to `tests` folder
cp "${CONTRACT_DIR}/compile/BasicToken.json" "${GIT_ROOT_DIR}/tests/src/token"