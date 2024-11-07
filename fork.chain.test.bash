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

cd "${PEAQ_NETWORK_NODE_FOLDER}" || { echo_report "${REPORT_PATH}" "Error: ${PEAQ_NETWORK_NODE_FOLDER} not found"; exit 1; }
COMMIT=$(git log -n 1 --format=%H | cut -c 1-6)
OUT_FOLDER_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}/forked."${TEST_MODULE}"
SUMMARY_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}/summary
REPORT_PATH=${OUT_FOLDER_PATH}/report.log
ERROR_HAPPENED=0
START_DATETIME=$(date '+%Y-%m-%d-%H-%M')

mkdir -p "${OUT_FOLDER_PATH}"

echo_info "Start fork.chain.test.bash"
# start build
echo_highlight "Start build for the node ${COMMIT}"
cargo build --release --features on-chain-release-build | tee "${OUT_FOLDER_PATH}/build.log"
echo_highlight "Finished build ${COMMIT}"


# we don't need to pack image
if [[ $CHAIN == "peaq-dev" || $CHAIN == "all" ]]; then
	if ! forked_config_file=$(check_and_get_forked_config "${PEAQ_DEV_RPC_ENDPOINT}" "peaq-dev"); then
		echo_report "${REPORT_PATH}" "forked test peaq fail: config peaq-dev $forked_config_file"
		ERROR_HAPPENED=1
		exit 1
	fi
	
	if ! fork_folder=$(check_and_get_forked_folder "${PEAQ_DEV_RPC_ENDPOINT}" "peaq-dev"); then
		echo_report "${REPORT_PATH}" "forked test peaq fail: fork forder peaq-dev $fork_folder"
		ERROR_HAPPENED=1
		exit 1
	fi
	execute_forked_test_parachain_launch "${PEAQ_DEV_RPC_ENDPOINT}" "${forked_config_file}" "${fork_folder}"
	
	if ! execute_runtime_upgrade_pytest "peaq-dev" "${TEST_MODULE}" "${PEAQ_DEV_RUNTIME_MODULE_PATH}" "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "forked test peaq fail: peaq-dev test fail"
		ERROR_HAPPENED=1
	fi
fi

if [[ $CHAIN == "krest" || $CHAIN == "all" ]]; then
	
	if ! forked_config_file=$(check_and_get_forked_config "${KREST_RPC_ENDPOINT}" "krest"); then
		echo_report "${REPORT_PATH}" "forked test peaq fail: krest $forked_config_file"
		ERROR_HAPPENED=1
		exit 1
	fi
	
	if ! fork_folder=$(check_and_get_forked_folder "${KREST_RPC_ENDPOINT}" "krest"); then
		echo_report "${REPORT_PATH}" "forked test peaq fail: krest $fork_folder"
		ERROR_HAPPENED=1
		exit 1
	fi
	execute_forked_test_parachain_launch "${KREST_RPC_ENDPOINT}" "${forked_config_file}" "${fork_folder}"
	
	if ! execute_runtime_upgrade_pytest "krest" "${TEST_MODULE}" "${KREST_RUNTIME_MODULE_PATH}" "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "forked test peaq fail: krest test fail"
		ERROR_HAPPENED=1
	fi
fi

if [[ $CHAIN == "peaq" || $CHAIN == "all" ]]; then
	if ! forked_config_file=$(check_and_get_forked_config "${PEAQ_RPC_ENDPOINT}" "peaq"); then
		echo_report "${REPORT_PATH}" "forked test peaq fail: peaq $forked_config_file"
		ERROR_HAPPENED=1
		exit 1
	fi
	
	if ! fork_folder=$(check_and_get_forked_folder "${PEAQ_RPC_ENDPOINT}" "peaq"); then
		echo_report "${REPORT_PATH}" "forked test peaq fail: peaq $fork_folder"
		ERROR_HAPPENED=1
		exit 1
	fi
	execute_forked_test_parachain_launch "${PEAQ_RPC_ENDPOINT}" "${forked_config_file}" "${fork_folder}"
	
	if ! execute_runtime_upgrade_pytest "peaq" "${TEST_MODULE}" "${PEAQ_RUNTIME_MODULE_PATH}" "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "forked test peaq fail: peaq test fail"
		ERROR_HAPPENED=1
	fi
fi

if [ ${ERROR_HAPPENED} -ne 1 ]; then
	echo_report "${REPORT_PATH}" "forked test test finish: ${CHAIN}: success!!"
fi

FINISH_DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo_report "${REPORT_PATH}" "Finish forked chain test: From ${START_DATETIME} to ${FINISH_DATETIME}"
cat "${REPORT_PATH}" >> "${SUMMARY_PATH}"
echo_highlight "Please go to ${SUMMARY_PATH} or ${REPORT_PATH} check the report"
