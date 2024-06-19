#!/bin/bash

source _constant.bash


try_runtime_test() {
	local chain_name=$1
	local rpc_endpoint=$2
	local runtime_module_path=$3
    local log_file=$4/${chain_name}

	try-runtime \
	--runtime ${runtime_module_path} \
	on-runtime-upgrade live --uri ${rpc_endpoint} | tee ${log_file}
}
