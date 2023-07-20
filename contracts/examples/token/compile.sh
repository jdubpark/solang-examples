#!/bin/bash

GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
CONTRACT_DIR="${GIT_ROOT_DIR}/contracts/examples/token"

# mkdir "${CONTRACT_DIR}/compile"
solang compile --target solana "${CONTRACT_DIR}/BasicToken.sol" -o "${CONTRACT_DIR}/compile" -v
