#!/bin/bash

source _constant.bash

echo_info()  {
    echo -e "\033[42;30m$1\033[0m" | tee -a "${OUT_FOLDER_PATH}"/overall
}

echo_highlight()  {
    echo -e "\033[43;30m$1\033[0m" | tee -a "${OUT_FOLDER_PATH}"/overall
}

echo_error()  {
    echo -e "\033[41;30m$1\033[0m" | tee -a "${OUT_FOLDER_PATH}"/overall
}

echo_report() {
	REPORT_FILE=$1
	echo -e "\033[43;30m$2\033[0m"
	echo -e "$2" >> "${REPORT_FILE}"
}

cargo_build() {
	local argument=$1
    if [[ $argument == "" ]]; then
        cargo build --release
    else
        cargo build --release "${argument}"
    fi  
}

r_pack_peaq_docker_img() {
    cd "${PEAQ_NETWORK_NODE_FOLDER}" || exit
    local docker_tag="peaq_para_node:${1:-latest}"
    docker build -f scripts/Dockerfile.parachain-launch -t "${docker_tag}" .
}

get_spec_version() {
	local endpoint=$1
	local version
	version=$(curl -s -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"chain_getRuntimeVersion","params":[],"id":1}' "${endpoint}" | jq '.result.specVersion')
	echo "$version"
}

check_and_get_forked_folder() {
	local endpoint=$1
	local chain_name=$2
	local version
	version="$chain_name-v0.0.$(get_spec_version "$endpoint")"

	local folder=${FORKED_BINARY_FOLDER}/$version
	if ! [ -d "$folder" ]; then
		echo_highlight "$folder: not exist, force exit"
		exit 1
	fi

	local binary=$folder/peaq-node
	if ! [ -f "$binary" ]; then
		echo_highlight "$binary: not exist, force exit"
		exit 1
	fi
	echo "$folder"
}

check_and_get_forked_config() {
	local endpoint=$1
	local chain_name=$2
	local version
	version=$(get_spec_version "$endpoint")

	local config="${PARACHAIN_LAUNCH_FOLDER}/scripts/config.parachain.${chain_name}.forked.v0.0.${version}.yml"
	if ! [ -f "$config" ]; then
		echo_highlight "$config: not exist, force exit"
		exit 1
	fi
	echo "$config"
}


get_parachain_id() {
	local chain_name=$1
	if [ "$chain_name" == "peaq-dev" ]; then
	  echo "2000"
	elif [ "$chain_name" == "krest" ]; then
	  echo "2241"
	elif [ "$chain_name" == "peaq" ]; then
	  echo "3338"
	else
	  echo "Unknown parachain type: $TYPE"
	  exit 1
	fi
}

get_parachain_launch_chain_spec() {
	local chain_name=$1
	local parachain_id
	
	if ! parachain_id=$(get_parachain_id "$chain_name"); then
		echo_error "cannot get the parachain_id: ${chain_name}"
		exit 1
	fi
	if [ "$chain_name" == "peaq-dev" ]; then
	  echo "dev-local-${parachain_id}.json"
	elif [ "$chain_name" == "krest" ]; then
	  echo "krest-local-${parachain_id}.json"
	elif [ "$chain_name" == "peaq" ]; then
	  echo "peaq-local-${parachain_id}.json"
	else
	  echo "Unknown parachain type: $chain_name"
	  exit 1
	fi
}

get_code_key() {
	cd "${CI_FOLDER}" || exit
	CHAIN_PWD=$1 python3 tools/get_code.py --chain "$2"
}
