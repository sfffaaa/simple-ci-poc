#!/bin/bash

source _constant.bash
source _utils.bash
source _parachain.bash
source _test.bash


# TODO: Need to think about whether we should do the snapshot test
# TODO: Need to stop the collator if something wrongs

show_help() {
    echo "Usage: $0 [options]"
    echo "Usage: CHAIN_PWD="aabbcc" ./fork.chain.test.bash --chain peaq-dev"
    echo ""
    echo "Options:"
    echo "  --help, -h, Display this help and exit"
    echo "  --chain, -p, Specify a chain name to test (peaq-dev/krest/peaq/all)"
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

cd ${PEAQ_NETWORK_NODE_FOLDER}
COMMIT=`git log -n 1 --format=%H | cut -c 1-6`
OUT_FOLDER_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}/collator

mkdir -p ${OUT_FOLDER_PATH}

echo_info "Start fork.collator.test.bash"

# start build
echo_highlight "Start build for the node ${COMMIT}"
cargo build --release | tee ${OUT_FOLDER_PATH}/build.log
echo_highlight "Finished build ${COMMIT}"


# we don't need to pack image
if [[ $CHAIN == "peaq-dev" || $CHAIN == "all" ]]; then
	SURI=`get_code_key ${CHAIN_PWD} "peaq-dev"`
	if [ $? -ne 0 ]; then
		echo_error "cannot get the key"
		exit 1
	fi

	forked_config_file=`check_and_get_forked_config ${PEAQ_DEV_RPC_ENDPOINT} "peaq-dev"`
	if [ $? -ne 0 ]; then
		echo_error "forked test peaq fail: peaq-dev $forked_config_file"
		exit 1
	fi
	fork_folder=`check_and_get_forked_folder ${PEAQ_DEV_RPC_ENDPOINT} "peaq-dev"`
	if [ $? -ne 0 ]; then
		echo_error "forked test peaq fail: peaq-dev $fork_folder"
		exit 1
	fi
	execute_forked_collator_parachain_launch ${PEAQ_DEV_RPC_ENDPOINT} ${forked_config_file} ${fork_folder}
	execute_another_collator_node "${SURI}" "peaq-dev" ${fork_folder} ${OUT_FOLDER_PATH}
	if [ $? -ne 0 ]; then
		echo_error "forked test peaq fail: peaq-dev test fail"
		exit 1
	fi
	echo_highlight "start execute_runtime_upgrade_only"
	execute_runtime_upgrade_only "peaq-dev" "${PEAQ_DEV_RUNTIME_MODULE_PATH}" "${OUT_FOLDER_PATH}"
	if [ $? -ne 0 ]; then
		echo_error "cannot upgrade"
	fi
	execute_runtime_upgrade_pytest "peaq-dev" "test_did_add" ${PEAQ_DEV_RUNTIME_MODULE_PATH} ${OUT_FOLDER_PATH}
	reset_forked_collator_parachain_launch
fi

# we don't need to pack image
if [[ $CHAIN == "krest" || $CHAIN == "all" ]]; then
	SURI=`get_code_key ${CHAIN_PWD} "krest"`
	if [ $? -ne 0 ]; then
		echo_error "cannot get the key"
		exit 1
	fi

	forked_config_file=`check_and_get_forked_config ${KREST_RPC_ENDPOINT} "krest"`
	if [ $? -ne 0 ]; then
		echo_error "forked test krest fail: krest $forked_config_file"
		exit 1
	fi
	fork_folder=`check_and_get_forked_folder ${KREST_RPC_ENDPOINT} "krest"`
	if [ $? -ne 0 ]; then
		echo_error "forked test krest fail: krest $fork_folder"
		exit 1
	fi
	execute_forked_collator_parachain_launch ${KREST_RPC_ENDPOINT} ${forked_config_file} ${fork_folder}
	execute_another_collator_node "${SURI}" "krest" ${fork_folder} ${OUT_FOLDER_PATH}
	if [ $? -ne 0 ]; then
		echo_error "forked test peaq fail: krest test fail"
		exit 1
	fi
	echo_highlight "start execute_runtime_upgrade_only"
	execute_runtime_upgrade_only "krest" "${KREST_RUNTIME_MODULE_PATH}" "${OUT_FOLDER_PATH}"
	if [ $? -ne 0 ]; then
		echo_error "cannot upgrade"
	fi
	execute_runtime_upgrade_pytest "krest" "test_did_add" ${KREST_RUNTIME_MODULE_PATH} ${OUT_FOLDER_PATH}
	reset_forked_collator_parachain_launch
fi

# we don't need to pack image
if [[ $CHAIN == "peaq" || $CHAIN == "all" ]]; then
	SURI=`get_code_key ${CHAIN_PWD} "peaq"`
	if [ $? -ne 0 ]; then
		echo_error "cannot get the key"
		exit 1
	fi

	forked_config_file=`check_and_get_forked_config ${PEAQ_RPC_ENDPOINT} "peaq"`
	if [ $? -ne 0 ]; then
		echo_error "forked test peaq fail: peaq $forked_config_file"
		exit 1
	fi
	fork_folder=`check_and_get_forked_folder ${PEAQ_RPC_ENDPOINT} "peaq"`
	if [ $? -ne 0 ]; then
		echo_error "forked test peaq fail: peaq $fork_folder"
		exit 1
	fi
	execute_forked_collator_parachain_launch ${PEAQ_RPC_ENDPOINT} ${forked_config_file} ${fork_folder}
	execute_another_collator_node "${SURI}" "peaq" ${fork_folder} ${OUT_FOLDER_PATH}
	if [ $? -ne 0 ]; then
		echo_error "forked test peaq fail: peaq test fail"
		exit 1
	fi
	echo_highlight "start execute_runtime_upgrade_only"
	execute_runtime_upgrade_only "peaq" "${PEAQ_RUNTIME_MODULE_PATH}" "${OUT_FOLDER_PATH}"
	if [ $? -ne 0 ]; then
		echo_error "cannot upgrade"
	fi
	execute_runtime_upgrade_pytest "peaq" "test_did_add" ${PEAQ_RUNTIME_MODULE_PATH} ${OUT_FOLDER_PATH}
	reset_forked_collator_parachain_launch
fi
FINISH_DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo_highlight "Finish forked chain test: From ${DATETIME} to ${FINISH_DATETIME}"
