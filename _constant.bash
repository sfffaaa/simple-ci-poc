#!/bin/bash

WORK_DIRECTORY="/home/jaypan/Work/peaq/CI"
PEAQ_NETWORK_NODE_BRANCH="dev"
PEAQ_BC_TEST_BRANCH="main"
PARACHAIN_LAUNCH_BRANCH="feat/simple-ci"
RESULT_PATH="/home/jaypan/Work/peaq/CI/results"

FORKED_BINARY_FOLDER="/home/jaypan/Work/peaq/CI/binary"


DATETIME=$(date '+%Y-%m-%d-%H-%M')
SLEEP_TIME=120
PEAQ_NETWORK_NODE_FOLDER=${WORK_DIRECTORY}/peaq-network-node
PEAQ_BC_TEST_FOLDER=${WORK_DIRECTORY}/peaq-bc-test
PARACHAIN_LAUNCH_FOLDER=${WORK_DIRECTORY}/parachain-launch
CI_FOLDER=${WORK_DIRECTORY}/simple-ci-poc
PEAQ_DEV_RPC_ENDPOINT="https://rpcpc1-qa.agung.peaq.network"
KREST_RPC_ENDPOINT="https://erpc-krest.peaq.network"
PEAQ_RPC_ENDPOINT="https://erpc-mpfn1.peaq.network"
PEAQ_DEV_WSS_ENDPOINT="wss://rpcpc1-qa.agung.peaq.network"
KREST_WSS_ENDPOINT="wss://erpc-krest.peaq.network"
PEAQ_WSS_ENDPOINT="wss://erpc-mpfn1.peaq.network"

PEAQ_DEV_BUILD_RUNTIME_PATH=target/release/wbuild/peaq-dev-runtime/peaq_dev_runtime.compact.compressed.wasm
KREST_BUILD_RUNTIME_PATH=target/release/wbuild/peaq-krest-runtime/peaq_krest_runtime.compact.compressed.wasm
PEAQ_BUILD_RUNTIME_PATH=target/release/wbuild/peaq-runtime/peaq_runtime.compact.compressed.wasm
PEAQ_DEV_RUNTIME_MODULE_PATH=${WORK_DIRECTORY}/peaq-network-node/${PEAQ_DEV_BUILD_RUNTIME_PATH}
KREST_RUNTIME_MODULE_PATH=${WORK_DIRECTORY}/peaq-network-node/${KREST_BUILD_RUNTIME_PATH}
PEAQ_RUNTIME_MODULE_PATH=${WORK_DIRECTORY}/peaq-network-node/${PEAQ_BUILD_RUNTIME_PATH}

FORK_KEEP_COLLATOR="false"
FORK_KEEP_ASSET="true"
FORK_KEEP_PARACHAIN="false"

FORKED_COLLATOR_CHAIN_FOLDER="${PARACHAIN_LAUNCH_FOLDER}/chain-folder-need-delete"
