#!/bin/bash

source _constant.bash
source _utils.bash


execute_pytest() {
    local chain_name=$1
    local test_module=$2
    local log_file
    log_file=$(realpath "$3/${chain_name}")
    echo_highlight "Start test for ${chain_name}" | tee "${log_file}"
    (   
        cd "${WORK_DIRECTORY}"/peaq-bc-test || { echo_error "Cannot find peaq-bc-test"; exit 1; }
        if [ "${GLOBAL_VENV}" == "false" ]; then
            source "${WORK_DIRECTORY}"/venv/bin/activate
        fi
        if [[ $test_module == "all" ]]; then
            pytest | tee "${log_file}"
        elif [[ $test_module == "xcm" ]]; then
            pytest -m "${test_module}" | tee "${log_file}"
        elif [[ $test_module == *".py" ]]; then
            pytest -s tests/"${test_module}" | tee "${log_file}"
        else
            pytest -k "${test_module}" | tee "${log_file}"
        fi  
    )   
}

execute_runtime_upgrade_pytest() {
    local chain_name=$1
    local test_module=$2
    local runtime_path=$3
    local log_file
    log_file=$(realpath "$4/${chain_name}")
    echo_highlight "Start test for ${chain_name}" | tee "${log_file}"
    (   
        cd "${WORK_DIRECTORY}"/peaq-bc-test || exit
        if [ "${GLOBAL_VENV}" == "false" ]; then
            source "${WORK_DIRECTORY}"/venv/bin/activate
        fi
        RUNTIME_UPGRADE_PATH=${runtime_path} python3 tools/runtime_upgrade.py

        if [[ $test_module == "all" ]]; then
            RUNTIME_UPGRADE_PATH=${runtime_path} pytest | tee "${log_file}"
        elif [[ $test_module == "xcm" ]]; then
            RUNTIME_UPGRADE_PATH=${runtime_path} pytest -m "${test_module}" | tee "${log_file}"
        else
            RUNTIME_UPGRADE_PATH=${runtime_path} pytest -k "${test_module}" | tee "${log_file}"
        fi  
    )   

}

execute_runtime_upgrade_only() {
    local chain_name=$1
    local runtime_path=$2
    local log_file
    log_file=$(realpath "$3/${chain_name}")
    echo_highlight "Start runtime upgrade for ${chain_name}" | tee "${log_file}"
    (   
        cd "${WORK_DIRECTORY}"/peaq-bc-test || exit
        if [ "${GLOBAL_VENV}" == "false" ]; then
            source "${WORK_DIRECTORY}"/venv/bin/activate
        fi
        
        if ! RUNTIME_UPGRADE_PATH=${runtime_path} python3 tools/runtime_upgrade.py | tee "${log_file}"; then
            echo_error "Error happens...."
            exit 1
        fi
    ) || { echo_error "Error happens...."; exit 1; }
}

check_evm_node_run() {
    local log_file="$1/evm.log"
    local block_height
    block_height=$(curl -s http://127.0.0.1:20044 -H "Content-Type:application/json;charset=utf-8" -d \
        '{
            "jsonrpc":"2.0",
            "method":"eth_getBlockByNumber",
            "params":["latest", false],
            "id":1
         }' | jq '.result.number')
    local block_height_hex="${block_height//\"/}"

    for (( i=0; i<=1000; i++))
    do
        current_dec=$((block_height_hex - i))
        current_hex=$(printf "0x%X" "$current_dec")
        local out
        out=$(curl -s http://127.0.0.1:20044 -H "Content-Type:application/json;charset=utf-8" -d \
            '{
                "jsonrpc": "2.0",
                "id": 1,
                "method": "debug_traceBlockByNumber",
                "params": ["'"${current_hex}"'", {"tracer": "callTracer"}]
            }' | jq '.result[0].type != null')
        if [[ $out == "true" ]]; then
            curl -s http://127.0.0.1:20044 -H "Content-Type:application/json;charset=utf-8" -d \
                '{
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "debug_traceBlockByNumber",
                    "params": ["'"${current_hex}"'", {"tracer": "callTracer"}]
                }' | jq '.result' | tee -a "${log_file}"
            echo_highlight "Found the debug call successfully"
            return 0
        fi
    done
    echo_highlight "Cannot find the debug call"
    return 1
}
