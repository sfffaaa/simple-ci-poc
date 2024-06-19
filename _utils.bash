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
