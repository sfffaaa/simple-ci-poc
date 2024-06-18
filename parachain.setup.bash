#!/bin/bash

WORK_DIRECTORY="/home/jaypan/Work/peaq/CI"


function parachain-launch-generate() {
	local config_file=$1
	cd ${WORK_DIRECTORY}/parachain-launch
	rm -rf yoyo
	./bin/parachain-launch generate --config="${config_file}" --output=yoyo
}

function setup_run_test() {
	local chain=$1
}

(
	cd ${WORK_DIRECTORY}/parachain-launch/yoyo
	docker compose down -v
	
	cd ${WORK_DIRECTORY}/parachain-launch
	parachain-launch-generate ci.config/config.parachain.peaq-dev.yml
	sleep 120
	cd ${WORK_DIRECTORY}/peaq-bc-test
	source ${WORK_DIRECTORY}/venv/bin/activate
	pytest
)
