#!/bin/bash

source _constant.bash
source _utils.bash

r_parachain_generate() {
    local config_file=$1
    cd ${WORK_DIRECTORY}/parachain-launch
    rm -rf yoyo
    ./bin/parachain-launch generate --config="${config_file}" --output=yoyo
}

r_parachain_down() {
    cd ${WORK_DIRECTORY}/parachain-launch/yoyo
      docker compose down -v
}

r_parachain_up() {
    cd ${WORK_DIRECTORY}/parachain-launch/yoyo
    docker compose up --build -d
}


execute_parachain_launch() {
    local chain_name=$1
    local log_file=$2/${chain_name}
    echo_highlight "Running ${chain_name}"

    r_parachain_down | tee ${log_file}
    r_parachain_generate ci.config/config.parachain.${chain_name}.yml | tee ${log_file}
    r_parachain_up | tee ${log_file}

    echo_highlight "Sleep ${SLEEP_TIME} seconds for ${chain_name}" | tee ${log_file}
    sleep ${SLEEP_TIME}
    echo_highlight "Ready to test" | tee ${log_file}
}

execute_forked_parachain_launch_imp() {
    local rpc_endpoint=$1
    local forked_config_file=$2
    local forked_folder=$3
    local keep_collator=$4
	local log_file=$5/collator.log

    cd ${PARACHAIN_LAUNCH_FOLDER}
    # Already did the parachain down in the script

    RPC_ENDPOINT=${rpc_endpoint} \
    FORKED_CONFIG_FILE=${forked_config_file} \
    DOCKER_COMPOSE_FOLDER="yoyo" \
    FORK_FOLDER=${forked_folder} \
    KEEP_COLLATOR=${keep_collator} \
    KEEP_ASSET=${FORK_KEEP_ASSET} \
    KEEP_PARACHAIN=${FORK_KEEP_PARACHAIN} \
    sh -e -x forked.generated.sh

    sleep 30
    local peaq_run=`docker ps | grep peaq`
    if [[ $peaq_run == "" ]]; then
        echo_highlight "After forked parachain, it cannot work, need to double check the setting"
        exit 1
    fi

    # Already did the parachain up in the script
    sleep ${SLEEP_TIME}
}

execute_forked_test_parachain_launch() {
    local rpc_endpoint=$1
    local forked_config_file=$2
    local forked_folder=$3

    execute_forked_parachain_launch_imp $rpc_endpoint $forked_config_file $forked_folder "false"
}

execute_forked_collator_parachain_launch() {
    local rpc_endpoint=$1
    local forked_config_file=$2
    local forked_folder=$3
    execute_forked_parachain_launch_imp $rpc_endpoint $forked_config_file $forked_folder "true"
}

execute_another_collator_node() {
    local SURI=$1
    local chain_name=$2
    local forked_folder=$3
	local log_file=$4/$chain_name.collator

    local binary_path="$3/peaq-node"

    # Get the parachain launch's config
    local parachain_id=`get_parachain_id $chain_name`
    if [ $? -ne 0 ]; then
        echo_error "Cannot get the parachain id"
        exit 1
    fi
    local parachain_config_file=`get_parachain_launch_chain_spec $chain_name`
    if [ $? -ne 0 ]; then
        echo_error "Cannot get the parachain id"
        exit 1
    fi
    local parachain_config="${PARACHAIN_LAUNCH_FOLDER}/yoyo/${parachain_config_file}"
    local relaychain_config="${PARACHAIN_LAUNCH_FOLDER}/yoyo/rococo-local.json"

    # Get the peer_id
    cd ${CI_FOLDER}
    local peer_id=`python3 tools/get_peer_id.py --read docker --type peaq | grep Parachain | grep -oE 'Parachain Peer id: [^ ]+' | awk '{print $NF}'`

    if [[ $peer_id == "None" ]]; then
        echo_highlight "Cannot find the $peer_id"
        exit 1
    fi
    local parachain_bootnode="/ip4/127.0.0.1/tcp/40336/p2p/${peer_id}"

    # Start to setup
    cd ${PARACHAIN_LAUNCH_FOLDER}

    rm -rf $FORKED_COLLATOR_CHAIN_FOLDER
    mkdir $FORKED_COLLATOR_CHAIN_FOLDER
    
    ${binary_path} \
    key insert \
    --base-path ${FORKED_COLLATOR_CHAIN_FOLDER} \
    --chain ${parachain_config} \
    --scheme Sr25519 \
    --suri "$SURI" \
    --key-type aura

    ${binary_path} \
    --parachain-id ${parachain_id} \
    --collator \
    --chain ${parachain_config} \
    --port 50334 \
    --rpc-port 20044 \
    --base-path ${FORKED_COLLATOR_CHAIN_FOLDER} \
    --unsafe-rpc-external \
    --rpc-cors=all \
    --rpc-methods=Unsafe \
    --execution wasm \
    --bootnodes $parachain_bootnode \
    -- \
    --execution wasm \
    --chain $relaychain_config \
    --port 50345 \
    --rpc-port 20055 \
    --unsafe-rpc-external \
    --rpc-cors=all 2>&1 | tee ${log_file} &

    echo_highlight "Wait for the collator run"
	sleep 20
    echo_highlight "Wait for the collator start to generate block"
	for i in {0..64}
	do
		sleep 12
		grep "Compressed" ${log_file}
		if [ $? -eq 0 ]; then
			echo_highlight "Collator successfully generate a block"
			break
		fi
	done

	grep "Compressed" ${log_file}
	if [ $? -ne 0 ]; then
		echo_error "Collator cannot generate block"
		exit 1
	fi
}


reset_forked_collator_parachain_launch() {
    pid=`pgrep -f ${WORK_DIRECTORY}`
    kill -9 ${pid}
    rm -rf ${FORKED_COLLATOR_CHAIN_FOLDER}
}
