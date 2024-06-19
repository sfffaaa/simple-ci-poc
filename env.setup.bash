#!/bin/bash

source _constant.bash

# Check git install or not
git --version > /dev/null 2>&1 || {
	echo "Please install git"
	exit 1
}

docker --version > /dev/null 2>&1 || {
	echo "Please install docker"
	exit 1
}

docker compose version > /dev/null 2>&1 || {
	echo "Please install docker-compose"
	exit 1
}

yarn --version > /dev/null 2>&1 || {
	echo "Please install yarn"
	exit 1
}

# # TODO Need to check
# nvm --version > /dev/null 2>&1 || {
# 	echo "Please install nvm"
# 	exit 1
# }

jq --version > /dev/null 2>&1 || {
	echo "Please install jq"
	exit 1
}

subwasm --version > /dev/null 2>&1 || {
	echo "Please install subwasm"
	echo "https://github.com/chevdor/subwasm"
	echo "cargo install --locked --git https://github.com/chevdor/subwasm --tag v0.16.1"
	exit 1
}

try-runtime --version > /dev/null 2>&1 || {
	echo "Please install try-runtime"
	echo "https://paritytech.github.io/try-runtime-cli/try_runtime/"
	echo "cargo install --git https://github.com/paritytech/try-runtime-cli --locked"
	exit 1
}

# Setup the peaq-bc-test
cd ${WORK_DIRECTORY}
git clone --branch ${PEAQ_BC_TEST_BRANCH} git@github.com:peaqnetwork/peaq-bc-test.git
python3 -m venv ${WORK_DIRECTORY}/venv
source ${WORK_DIRECTORY}/venv/bin/activate
cd ${WORK_DIRECTORY}/peaq-bc-test
pip3 install -r requirements.txt

# Setup the peaq-network-node
cd ${WORK_DIRECTORY}
git clone --branch ${PEAQ_NETWORK_NODE_BRANCH} git@github.com:peaqnetwork/peaq-network-node.git

# Setup the parachain-launch
cd ${WORK_DIRECTORY}
git clone --branch ${PARACHAIN_LAUNCH_BRANCH} git@github.com:peaqnetwork/parachain-launch.git
cd ${WORK_DIRECTORY}/parachain-launch
yarn build
# error detective-postcss@5.1.1: The engine "node" is incompatible with this module. Expected version "12.x || 14.x || 16.x". Got "18.19.1"
# nvm install 16
# nvm use 16
yarn install

# Setup the parachain-launch's fork-off-project
cd ${WORK_DIRECTORY}/parachain-launch
git submodule update --init --recursive
cd fork-off-substrate
npm install
