#!/bin/bash

GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
CONTRACT_DIR="${GIT_ROOT_DIR}/contracts/examples/flipper"

# mkdir "${CONTRACT_DIR}/compile"
solang compile --target solana "${CONTRACT_DIR}/Flipper.sol" -o "${CONTRACT_DIR}/compile"
