#!/bin/bash

source _constant.bash
source _utils.bash
source _parachain.bash
source _test.bash


show_help() {
    echo "Usage: $0 [options]"
    echo "Usage: ./fork.chain.test.bash --chain peaq-dev --test all"
    echo ""
    echo "Options:"
    echo "  --help, -h, Display this help and exit"
    echo "  --chain, -p, Specify a chain name to test (peaq-dev/krest/peaq/all)"
    echo "  --test, -t, Specify a test name to run test suit (all/xcm/test_case_name)"
    # Add more options and descriptions here
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
OUT_FOLDER_PATH=${RESULT_PATH}/forked/${DATETIME}.${COMMIT}."${TEST_MODULE}"

mkdir -p ${OUT_FOLDER_PATH}

# start build
echo_highlight "Start build for the node ${COMMIT}"
cargo build --release | tee ${OUT_FOLDER_PATH}/build.log
echo_highlight "Finished build ${COMMIT}"


# we don't need to pack image
if [[ $CHAIN == "peaq-dev" || $CHAIN == "all" ]]; then
	forked_config_file=`check_and_get_forked_config ${PEAQ_DEV_RPC_ENDPOINT} "peaq-dev"`
	if [ $? -ne 0 ]; then
		echo_highlight $forked_config_file
		exit 1
	fi
	fork_folder=`check_and_get_forked_folder ${PEAQ_DEV_RPC_ENDPOINT} "peaq-dev"`
	if [ $? -ne 0 ]; then
		echo_highlight $fork_folder
		exit 1
	fi
	execute_forked_parachain_launch ${PEAQ_DEV_RPC_ENDPOINT} ${forked_config_file} ${fork_folder}
	execute_runtime_upgrade_pytest "peaq-dev" ${TEST_MODULE} ${PEAQ_DEV_RUNTIME_MODULE_PATH} ${OUT_FOLDER_PATH}
fi

if [[ $CHAIN == "krest" || $CHAIN == "all" ]]; then
	forked_config_file=`check_and_get_forked_config ${KREST_RPC_ENDPOINT} "krest"`
	if [ $? -ne 0 ]; then
		echo_highlight $forked_config_file
		exit 1
	fi
	fork_folder=`check_and_get_forked_folder ${KREST_RPC_ENDPOINT} "krest"`
	if [ $? -ne 0 ]; then
		echo_highlight $fork_folder
		exit 1
	fi
	execute_forked_parachain_launch ${KREST_RPC_ENDPOINT} ${forked_config_file} ${fork_folder}
	execute_runtime_upgrade_pytest "krest" ${TEST_MODULE} ${KREST_RUNTIME_MODULE_PATH} ${OUT_FOLDER_PATH}
	exit 0
fi

if [[ $CHAIN == "peaq" || $CHAIN == "all" ]]; then
	forked_config_file=`check_and_get_forked_config ${PEAQ_RPC_ENDPOINT} "peaq"`
	if [ $? -ne 0 ]; then
		echo_highlight $forked_config_file
		exit 1
	fi
	fork_folder=`check_and_get_forked_folder ${PEAQ_RPC_ENDPOINT} "peaq"`
	if [ $? -ne 0 ]; then
		echo_highlight $fork_folder
		exit 1
	fi
	execute_forked_parachain_launch ${PEAQ_RPC_ENDPOINT} ${forked_config_file} ${fork_folder}
	execute_runtime_upgrade_pytest "peaq" ${TEST_MODULE} ${PEAQ_RUNTIME_MODULE_PATH} ${OUT_FOLDER_PATH}
fi

FINISH_DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo_highlight "Finish forked chain test: From ${DATETIME} to ${FINISH_DATETIME}"
