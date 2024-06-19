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

execute_forked_parachain_launch() {
	local rpc_endpoint=$1
	local forked_config_file=$2
	local forked_folder=$3

	cd ${PARACHAIN_LAUNCH_FOLDER}
	# Already did the parachain down in the script

	RPC_ENDPOINT=${rpc_endpoint} \
	FORKED_CONFIG_FILE=${forked_config_file} \
	DOCKER_COMPOSE_FOLDER="yoyo" \
	FORK_FOLDER=${forked_folder} \
	KEEP_COLLATOR=${FORK_KEEP_COLLATOR} \
	KEEP_ASSET=${FORK_KEEP_ASSET} \
	KEEP_PARACHAIN=${FORK_KEEP_PARACHAIN} \
	sh -e -x forked.generated.sh

	sleep 3
	local peaq_run=`docker ps | grep peaq`
	if [[ $peaq_run == "" ]]; then
		echo_highlight "After forked parachain, it cannot work, need to double check the setting"
		exit 1
	fi

	# Already did the parachain up in the script
    sleep ${SLEEP_TIME}
}
