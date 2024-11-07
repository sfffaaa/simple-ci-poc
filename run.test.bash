#!/bin/bash

# CHAIN_PWD="aabb" bash run.test.bash

DATETIME=$(date '+%Y-%m-%d-%H-%M')
WORK_DIRECTORY="/home/jaypan/Work/peaq"
PEAQ_NETWORK_NODE_BRANCH="release-delegator-update"
echo "${DATETIME}"

# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME}  bash evm.wasm.test.bash --chain peaq-dev
# SET_DATETIME=${DATETIME} bash evm.wasm.test.bash --chain krest
# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME} bash evm.wasm.test.bash --chain peaq

# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME} bash -x try-runtime.test.bash --chain peaq-dev
# SET_DATETIME=${DATETIME} bash try-runtime.test.bash --chain krest
# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME} bash -x try-runtime.test.bash --chain peaq

# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME} bash new.chain.test.bash --chain peaq-dev --test all
# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME} bash -x fork.chain.test.bash --chain peaq-dev --test all
# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME}  bash fork.collator.test.bash --chain peaq-dev

# SET_DATETIME=${DATETIME} bash new.chain.test.bash --chain krest --test all
# SET_DATETIME=${DATETIME} bash fork.chain.test.bash --chain krest --test all
# SET_DATETIME=${DATETIME} bash fork.collator.test.bash --chain krest
# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME}
# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME} bash new.chain.test.bash --chain peaq --test all
PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME} bash fork.chain.test.bash --chain peaq --test all
# PEAQ_NETWORK_NODE_BRANCH=${PEAQ_NETWORK_NODE_BRANCH} WORK_DIRECTORY=${WORK_DIRECTORY} SET_DATETIME=${DATETIME} bash fork.collator.test.bash --chain peaq
