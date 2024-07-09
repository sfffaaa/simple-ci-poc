#!/bin/bash

source _constant.bash
source _utils.bash


try_runtime_test() {
    local chain_name=$1
    local wss_endpoint=$2
    local runtime_module_path=$3
    local log_file=$4/${chain_name}

    cd "${PEAQ_NETWORK_NODE_FOLDER}" || exit
    try-runtime \
    --runtime "${runtime_module_path}" \
    on-runtime-upgrade live --uri "${wss_endpoint}" 2>&1 | tee "${log_file}"
}
