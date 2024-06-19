#!/bin/bash

source _constant.bash

echo_highlight()  {
    echo -e "\033[43;30m$1\033[0m" | tee -a ${OUT_FOLDER_PATH}/overall
}

cargo_build() {
	local argument=$1
    if [[ $argument == "" ]]; then
        cargo build --release
    else
        cargo build --release ${argument}
    fi  
}

r_pack_peaq_docker_img() {
    cd ${PEAQ_NETWORK_NODE_FOLDER}
    local docker_tag="peaq_para_node:${1:-latest}"
    docker build -f scripts/Dockerfile.parachain-launch -t "${docker_tag}" .
}

get_spec_version() {
	local endpoint=$1
	local version=`curl -s -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"chain_getRuntimeVersion","params":[],"id":1}' ${endpoint} | jq '.result.specVersion'`
	echo "$version"
}

check_and_get_forked_folder() {
	local endpoint=$1
	local chain_name=$2
	local version="$chain_name-v0.0.$(get_spec_version $endpoint)"

	local folder=${FORKED_BINARY_FOLDER}/$version
	if ! [ -d $folder ]; then
		echo_highlight "$folder: not exist, force exit"
		exit 1
	fi

	local binary=$folder/peaq-node
	if ! [ -f $binary ]; then
		echo_highlight "$binary: not exist, force exit"
		exit 1
	fi
	echo $folder
}

check_and_get_forked_config() {
	local endpoint=$1
	local chain_name=$2
	local version=$(get_spec_version $endpoint)

	local config="${PARACHAIN_LAUNCH_FOLDER}/scripts/config.parachain.${chain_name}.forked.v0.0.${version}.yml"
	if ! [ -f $config ]; then
		echo_highlight "$config: not exist, force exit"
		exit 1
	fi
	echo $config
}
