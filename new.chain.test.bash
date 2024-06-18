#!/bin/bash

WORK_DIRECTORY="/home/jaypan/Work/peaq/CI"
PEAQ_NETWORK_NODE_FOLDER=${WORK_DIRECTORY}/peaq-network-node
PEAQ_BC_TEST_FOLDER=${WORK_DIRECTORY}/peaq-bc-test
PARACHAIN_LAUNCH_FOLDER=${WORK_DIRECTORY}/parachain-launch
RESULT_PATH="/home/jaypan/Work/peaq/CI/results"
DATETIME=$(date '+%Y-%m-%d-%H-%M-%S')
SLEEP_TIME=120

show_help() {
    echo "Usage: $0 [options]"
    echo "Usage: ./new.chain.test.bash --chain peaq-dev --test all"
    echo ""
    echo "Options:"
    echo "  --help, -h, Display this help and exit"
    echo "  --chain, -p, Specify a chain name to test (peaq-dev/krest/peaq/all)"
    echo "  --test, -t, Specify a test name to run test suit (all/xcm/test_case_name)"
    # Add more options and descriptions here
}


r_pack_peaq_docker_img() {
    cd ${PEAQ_NETWORK_NODE_FOLDER}
    local docker_tag="peaq_para_node:${1:-latest}"
    docker build -f scripts/Dockerfile.parachain-launch -t "${docker_tag}" .
}

echo_highlight()  {
    echo -e "\033[43;30m$1\033[0m" | tee -a ${OUT_FOLDER_PATH}/overall
}

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
	docker compose up -d
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
            exit 1
        fi  
    )   
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --help|-h)
            show_help
            exit 0
            ;;
        # Add more options handling here if needed
        --chain|-c)
            CHAIN=$2
            shift
            ;;
        --test|-t)
            TEST_MODULE=$2
            shift
            ;;
        *)
            echo "Unknown option: $key"
            show_help
            exit 1
            ;;
    esac
    shift
done

if [[ -z "$CHAIN" ]]; then
    echo "Error: --chain/-c is required"
    echo ""
    show_help
    exit 1
fi

if [[ -z "$TEST_MODULE" ]]; then
    echo "Error: --test/-t is required"
    echo ""
    show_help
    exit 1
fi


cd ${PEAQ_NETWORK_NODE_FOLDER}
COMMIT=`git log -n 1 --format=%H | cut -c 1-6`
OUT_FOLDER_PATH=${RESULT_PATH}/${DATETIME}-${COMMIT}
mkdir -p ${OUT_FOLDER_PATH}

echo_highlight "Start build for the node ${COMMIT}"
cargo build --release | tee ${OUT_FOLDER_PATH}/build.log
echo_highlight "Finished build ${COMMIT}"


# pack image
r_pack_peaq_docker_img "latest"
r_pack_peaq_docker_img "${COMMIT}"

echo_highlight "Finished pack docker image, ${COMMIT} + latest"

if [[ $CHAIN == "peaq-dev" ]]; then
	execute_parachain_launch "peaq-dev" ${OUT_FOLDER_PATH}
	execute_pytest "peaq-dev" ${TEST_MODULE} ${OUT_FOLDER_PATH}
	exit 0
fi
if [[ $CHAIN == "krest" ]]; then
	execute_parachain_launch "krest" ${OUT_FOLDER_PATH}
	execute_pytest "krest" ${TEST_MODULE} ${OUT_FOLDER_PATH}
	exit 0
fi
if [[ $CHAIN == "peaq" ]]; then
	execute_parachain_launch "peaq" ${OUT_FOLDER_PATH}
	execute_pytest "peaq" ${TEST_MODULE} ${OUT_FOLDER_PATH}
	exit 0
fi
if [[ $CHAIN == "all" ]]; then
	execute_parachain_launch "peaq-dev" ${OUT_FOLDER_PATH}
	execute_pytest "peaq-dev" ${TEST_MODULE} ${OUT_FOLDER_PATH}
	execute_parachain_launch "krest" ${OUT_FOLDER_PATH}
	execute_pytest "peaq-dev" ${TEST_MODULE} ${OUT_FOLDER_PATH}
	execute_parachain_launch "peaq" ${OUT_FOLDER_PATH}
	execute_pytest "peaq-dev" ${TEST_MODULE} ${OUT_FOLDER_PATH}
	exit 0
fi
