#!/bin/bash

source _constant.bash
source _parachain.bash
source _test.bash
source _utils.bash

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


cd "${PEAQ_NETWORK_NODE_FOLDER}" || { echo_red "Error: ${PEAQ_NETWORK_NODE_FOLDER} not found"; exit 1; }
COMMIT=$(git log -n 1 --format=%H | cut -c 1-6)
OUT_FOLDER_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}/new."${TEST_MODULE}"
SUMMARY_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}/summary
REPORT_PATH=${OUT_FOLDER_PATH}/report.log
ERROR_HAPPENED=0
START_DATETIME=$(date '+%Y-%m-%d-%H-%M')

mkdir -p "${OUT_FOLDER_PATH}"

echo_info "Start new.chain.test.bash"

echo_highlight "Start build for the node ${COMMIT}"
cargo build --release | tee "${OUT_FOLDER_PATH}"/build.log
echo_highlight "Finished build ${COMMIT}"

# pack image
r_pack_peaq_docker_img "latest"
r_pack_peaq_docker_img "${COMMIT}"

echo_highlight "Finished pack docker image, ${COMMIT} + latest"

if [[ $CHAIN == "peaq-dev" || $CHAIN == "all" ]]; then
	execute_parachain_launch "peaq-dev" "${OUT_FOLDER_PATH}"
	
	if ! execute_pytest "peaq-dev" "${TEST_MODULE}" "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "new test peaq fail: peaq-dev test fail"
		ERROR_HAPPENED=1
	fi
fi
if [[ $CHAIN == "krest" || $CHAIN == "all" ]]; then
	execute_parachain_launch "krest" "${OUT_FOLDER_PATH}"
	
	if ! execute_pytest "krest" "${TEST_MODULE}" "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "new test peaq fail: krest test fail"
		ERROR_HAPPENED=1
	fi
fi
if [[ $CHAIN == "peaq" || $CHAIN == "all" ]]; then
	execute_parachain_launch "peaq" "${OUT_FOLDER_PATH}"
	
	if ! execute_pytest "peaq" "${TEST_MODULE}" "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "new test peaq fail: peaq test fail"
		ERROR_HAPPENED=1
	fi
fi

if [ ${ERROR_HAPPENED} -ne 1 ]; then
	echo_report "${REPORT_PATH}" "new chain test finish: ${CHAIN}: success!!"
fi

FINISH_DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo_report "${REPORT_PATH}" "Finish new chain test: From ${START_DATETIME} to ${FINISH_DATETIME}"
cat "${REPORT_PATH}" >> "${SUMMARY_PATH}"
echo_highlight "Please go to ${SUMMARY_PATH} or ${REPORT_PATH} check the report"

if [ ${ERROR_HAPPENED} -eq 1 ]; then
	exit 1
fi
