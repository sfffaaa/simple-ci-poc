#!/bin/bash

WORK_DIRECTORY="/home/jaypan/Work/peaq/CI"
PEAQ_NETWORK_NODE_FOLDER=${WORK_DIRECTORY}/peaq-network-node
PEAQ_BC_TEST_FOLDER=${WORK_DIRECTORY}/peaq-bc-test
PARACHAIN_LAUNCH_FOLDER=${WORK_DIRECTORY}/parachain-launch

function r_pack_peaq_docker_img() {
    cd ${PEAQ_NETWORK_NODE_FOLDER}
    local docker_tag="peaq_para_node:${1:-latest}"
    docker build -f scripts/Dockerfile.parachain-launch -t "${docker_tag}" .
    cd -
}                                                                                                                                



cd ${PEAQ_NETWORK_NODE_FOLDER}
cargo build --release


# pack image
local docker_tag="peaq_para_node:latest"
commit=(git log -n 1 --format=%H | cut -c 1-6)
r_pack_peaq_docker_img "latest"
r_pack_peaq_docker_img ${commit}
