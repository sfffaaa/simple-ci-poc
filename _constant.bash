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
