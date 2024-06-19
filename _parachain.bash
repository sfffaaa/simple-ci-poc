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
    sleep 120
    echo_highlight "Ready to test" | tee ${log_file}
}
