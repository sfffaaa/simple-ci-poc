#!/bin/bash

source _constant.bash
source _utils.bash


execute_pytest() {
    local chain_name=$1
    local test_module=$2
    local log_file=$3/${chain_name}
    echo_highlight "Start test for ${chain_name}" | tee ${log_file}
    (   
        cd ${WORK_DIRECTORY}/peaq-bc-test
        source ${WORK_DIRECTORY}/venv/bin/activate
        if [[ $test_module == "all" ]]; then
            pytest | tee ${log_file}
        elif [[ $test_module == "xcm" ]]; then
            pytest -m ${test_module} | tee ${log_file}
        else
            pytest -k ${test_module} | tee ${log_file}
        fi  
    )   
}

execute_runtime_upgrade_pytest() {
    local chain_name=$1
    local test_module=$2
    local runtime_path=$3
    local log_file=$4/${chain_name}
    echo_highlight "Start test for ${chain_name}" | tee ${log_file}
    (   
        cd ${WORK_DIRECTORY}/peaq-bc-test
        source ${WORK_DIRECTORY}/venv/bin/activate
        RUNTIME_UPGRADE_PATH=${runtime_path} python3 tools/runtime_upgrade.py

        if [[ $test_module == "all" ]]; then
            RUNTIME_UPGRADE_PATH=${runtime_path} pytest | tee ${log_file}
        elif [[ $test_module == "xcm" ]]; then
            RUNTIME_UPGRADE_PATH=${runtime_path} pytest -m ${test_module} | tee ${log_file}
        else
            RUNTIME_UPGRADE_PATH=${runtime_path} pytest -k ${test_module} | tee ${log_file}
        fi  
    )   

}
