#!/bin/bash

source _constant.bash
source _utils.bash

r_parachain_generate() {
    local config_file=$1
    cd "${WORK_DIRECTORY}"/parachain-launch || { echo_error "Cannot find the parachain-launch folder"; exit 1; }
    rm -rf yoyo
    ./bin/parachain-launch generate --config="${config_file}" --output=yoyo
}

r_parachain_down() {
    cd "${WORK_DIRECTORY}"/parachain-launch/yoyo || { echo_error "Cannot find the parachain-launch folder"; exit 1; }
    docker compose -f "${WORK_DIRECTORY}"/parachain-launch/yoyo/docker-compose.yml down -v
}

r_parachain_up() {
    cd "${WORK_DIRECTORY}"/parachain-launch/yoyo || { echo_error "Cannot find the parachain-launch folder"; exit 1; }
    docker compose -f "${WORK_DIRECTORY}"/parachain-launch/yoyo/docker-compose.yml up --build -d
}


execute_parachain_launch() {
    local chain_name=$1
    local log_file=$2/${chain_name}
    echo_highlight "Running ${chain_name}"

    r_parachain_down | tee "${log_file}"
    r_parachain_generate ci.config/config.parachain."${chain_name}".yml | tee "${log_file}"
    r_parachain_up | tee "${log_file}"

    echo_highlight "Sleep ${SLEEP_TIME} seconds for ${chain_name}" | tee "${log_file}"
    sleep "${SLEEP_TIME}"
    echo_highlight "Ready to test" | tee "${log_file}"
}

execute_forked_parachain_launch_imp() {
    local rpc_endpoint=$1
    local forked_config_file=$2
    local forked_folder=$3
    local keep_collator=$4
    local log_file=$5/collator.log

    cd "${PARACHAIN_LAUNCH_FOLDER}" || { echo_error "Cannot find the parachain-launch folder"; exit 1; }
    # Already did the parachain down in the script

    RPC_ENDPOINT=${rpc_endpoint} \
    FORKED_CONFIG_FILE=${forked_config_file} \
    DOCKER_COMPOSE_FOLDER="yoyo" \
    FORK_FOLDER=${forked_folder} \
    KEEP_COLLATOR=${keep_collator} \
    KEEP_ASSET=${FORK_KEEP_ASSET} \
    KEEP_PARACHAIN=${FORK_KEEP_PARACHAIN} \
    sh -e -x forked.generated.sh

       echo_highlight "Sleep 30 for the checking"
    sleep 30
    local peaq_run
    peaq_run=$(docker ps | grep peaq)
    if [[ -z $peaq_run ]]; then
        echo_highlight "After forked parachain, it cannot work, need to double check the setting"
        exit 1
    fi

    echo_highlight "Sleep ${SLEEP_TIME}"
    # Already did the parachain up in the script
    sleep "${SLEEP_TIME}"
}

execute_forked_test_parachain_launch() {
    local rpc_endpoint=$1
    local forked_config_file=$2
    local forked_folder=$3

    execute_forked_parachain_launch_imp "$rpc_endpoint" "$forked_config_file" "$forked_folder" "false"
}

execute_forked_collator_parachain_launch() {
    local rpc_endpoint=$1
    local forked_config_file=$2
    local forked_folder=$3
    execute_forked_parachain_launch_imp "$rpc_endpoint" "$forked_config_file" "$forked_folder" "true"
}

execute_another_collator_node() {
    local SURI=$1
    local chain_name=$2
    local forked_folder=$3
    local log_file=$4/$chain_name.collator

    local binary_path="$3/peaq-node"

    # Get the parachain launch's config
    local parachain_id
    if ! parachain_id=$(get_parachain_id "$chain_name"); then
        echo_error "Cannot get the parachain id"
        exit 1
    fi
    local parachain_config_file
    if ! parachain_config_file=$(get_parachain_launch_chain_spec "$chain_name"); then
        echo_error "Cannot get the parachain id"
        exit 1
    fi
    local parachain_config="${PARACHAIN_LAUNCH_FOLDER}/yoyo/${parachain_config_file}"
    local relaychain_config="${PARACHAIN_LAUNCH_FOLDER}/yoyo/rococo-local.json"

    # Get the peer_id
    cd "${CI_FOLDER}" || { echo_error "Cannot find the ci folder"; exit 1; }
    local peer_id
    peer_id=$(python3 tools/get_peer_id.py --read docker --type peaq | grep Parachain | grep -oE 'Parachain Peer id: [^ ]+' | awk '{print $NF}')

    if [[ $peer_id == "None" ]]; then
        echo_highlight "Cannot find the $peer_id"
        exit 1
    fi
    local parachain_bootnode="/ip4/127.0.0.1/tcp/40336/p2p/${peer_id}"

    # Start to setup
    cd "${PARACHAIN_LAUNCH_FOLDER}" || { echo_error "Cannot find the parachain-launch folder"; exit 1; }

    rm -rf "${FORKED_COLLATOR_CHAIN_FOLDER}"
    mkdir "${FORKED_COLLATOR_CHAIN_FOLDER}"
    
    ${binary_path} \
    key insert \
    --base-path "${FORKED_COLLATOR_CHAIN_FOLDER}" \
    --chain "${parachain_config}" \
    --scheme Sr25519 \
    --suri "$SURI" \
    --key-type aura

	echo "    ${binary_path} \
    --parachain-id "${parachain_id}" \
    --collator \
    --chain "${parachain_config}" \
    --port 50334 \
    --rpc-port 20044 \
    --base-path "${FORKED_COLLATOR_CHAIN_FOLDER}" \
    --unsafe-rpc-external \
    --rpc-cors=all \
    --rpc-methods=Unsafe \
    --execution wasm \
    --bootnodes "$parachain_bootnode" \
    -- \
    --execution wasm \
    --chain "$relaychain_config" \
    --port 50345 \
    --rpc-port 20055 \
    --unsafe-rpc-external \
    --rpc-cors=all"

    ${binary_path} \
    --parachain-id "${parachain_id}" \
    --collator \
    --chain "${parachain_config}" \
    --port 50334 \
    --rpc-port 20044 \
    --base-path "${FORKED_COLLATOR_CHAIN_FOLDER}" \
    --unsafe-rpc-external \
    --rpc-cors=all \
    --rpc-methods=Unsafe \
    --execution wasm \
    --bootnodes "$parachain_bootnode" \
    -- \
    --execution wasm \
    --chain "$relaychain_config" \
    --port 50345 \
    --rpc-port 20055 \
    --unsafe-rpc-external \
    --rpc-cors=all 2>&1 | tee "${log_file}" &

    echo_highlight "Wait for the collator run"
    sleep 20
    echo_highlight "Wait for the collator start to generate block"
    for _i in {0..128}
    do
        sleep 12
        if grep "Compressed" "${log_file}"; then
            echo_highlight "Collator successfully generate a block"
            break
        fi
    done

    if ! grep "Compressed" "${log_file}"; then
        echo_error "Collator cannot generate block"
        exit 1
    fi
}

execute_evm_node() {
    local chain_name=$1
    local wasm_folder_path=$2
    local log_file=$3/$chain_name.evm

    # Get the parachain launch's config
    local parachain_id
    if ! parachain_id=$(get_parachain_id "$chain_name"); then
        echo_error "Cannot get the parachain id"
        exit 1
    fi
    local parachain_config_file
    if ! parachain_config_file=$(get_parachain_launch_chain_spec "$chain_name"); then
        echo_error "Cannot get the parachain id"
        exit 1
    fi
    local parachain_config="${PARACHAIN_LAUNCH_FOLDER}/yoyo/${parachain_config_file}"
    local relaychain_config="${PARACHAIN_LAUNCH_FOLDER}/yoyo/rococo-local.json"

    # Get the peer_id
    cd "${CI_FOLDER}" || { echo_error "Cannot find the ci folder"; exit 1; }
    local peer_id
    peer_id=$(python3 tools/get_peer_id.py --read docker --type peaq | grep Parachain | grep -oE 'Parachain Peer id: [^ ]+' | awk '{print $NF}')

    if [[ $peer_id == "None" ]]; then
        echo_highlight "Cannot find the $peer_id"
        exit 1
    fi
    local parachain_bootnode="/ip4/127.0.0.1/tcp/40336/p2p/${peer_id}"

    # Start to setup
    cd "${PARACHAIN_LAUNCH_FOLDER}" || { echo_error "Cannot find the parachain-launch folder"; exit 1; }

    rm -rf "${EVM_NODE_CHAIN_FOLDER}"
    mkdir "${EVM_NODE_CHAIN_FOLDER}"
  
    echo "${PEAQ_NODE_BINARY_PATH}" \
    --parachain-id "${parachain_id}" \
    --chain "${parachain_config}" \
    --port 50334 \
    --rpc-port 20044 \
    --base-path "${EVM_NODE_CHAIN_FOLDER}" \
    --unsafe-rpc-external \
    --rpc-cors=all \
    --rpc-methods=Unsafe \
    --ethapi=debug,trace,txpool \
    --execution wasm \
    --wasm-runtime-overrides "${wasm_folder_path}" \
    --bootnodes "$parachain_bootnode" \
    -- \
    --execution wasm \
    --chain "$relaychain_config" \
    --port 50345 \
    --rpc-port 20055 \
    --unsafe-rpc-external \
    --rpc-cors=all

    ${PEAQ_NODE_BINARY_PATH} \
    --parachain-id "${parachain_id}" \
    --chain "${parachain_config}" \
    --port 50334 \
    --rpc-port 20044 \
    --base-path "${EVM_NODE_CHAIN_FOLDER}" \
    --unsafe-rpc-external \
    --rpc-cors=all \
    --rpc-methods=Unsafe \
    --ethapi=debug,trace,txpool \
    --execution wasm \
    --wasm-runtime-overrides "${wasm_folder_path}" \
    --bootnodes "$parachain_bootnode" \
    -- \
    --execution wasm \
    --chain "$relaychain_config" \
    --port 50345 \
    --rpc-port 20055 \
    --unsafe-rpc-external \
    --rpc-cors=all 2>&1 | tee "${log_file}" &

    echo_highlight "Wait for the evm node run"
    sleep 20
    echo_highlight "Finish the evm node start"
}

kill_peaq_node() {
	pkill peaq-node
}

reset_forked_collator() {
    kill_peaq_node
    rm -rf "${FORKED_COLLATOR_CHAIN_FOLDER}"
}

reset_evm_node() {
    kill_peaq_node
    rm -rf "${EVM_NODE_CHAIN_FOLDER}"
}
