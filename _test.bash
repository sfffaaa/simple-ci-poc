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
