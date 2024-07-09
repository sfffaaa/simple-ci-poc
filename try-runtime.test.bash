#!/bin/bash

source _constant.bash
source _tryruntime.bash
source _utils.bash

show_help() {
    echo "Usage: $0 [options]"
    echo "Usage: ./try-runtime.test.bash --chain peaq-dev"
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

cd "${PEAQ_NETWORK_NODE_FOLDER}" || { echo_red "Error: ${PEAQ_NETWORK_NODE_FOLDER} does not exist"; exit 1; }
COMMIT=$(git log -n 1 --format=%H | cut -c 1-6)
OUT_FOLDER_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}/try-runtime
SUMMARY_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}/summary
REPORT_PATH=${OUT_FOLDER_PATH}/report.log
ERROR_HAPPENED=0
START_DATETIME=$(date '+%Y-%m-%d-%H-%M')

mkdir -p "${OUT_FOLDER_PATH}"
echo_info "Start try-runtime.test.bash"

echo_highlight "Start build for the node ${COMMIT}"
cargo build --release --features=try-runtime | tee "${OUT_FOLDER_PATH}"/build.log
echo_highlight "Finished build ${COMMIT}"

if [[ $CHAIN == "peaq-dev" || $CHAIN == "all" ]]; then
	
	if ! try_runtime_test "peaq-dev" "${PEAQ_DEV_WSS_ENDPOINT}" "${PEAQ_DEV_BUILD_RUNTIME_PATH}"  "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "Try-runtime peaq-dev error!!!"
		ERROR_HAPPENED=1
	fi
fi
if [[ $CHAIN == "krest" || $CHAIN == "all" ]]; then
	
	if ! try_runtime_test "krest" "${KREST_WSS_ENDPOINT}" "${KREST_BUILD_RUNTIME_PATH}"  "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "Try-runtime krest error!!!"
		ERROR_HAPPENED=1
	fi
fi
if [[ $CHAIN == "peaq" || $CHAIN == "all" ]]; then
	
	if ! try_runtime_test "peaq" "${PEAQ_WSS_ENDPOINT}" "${PEAQ_BUILD_RUNTIME_PATH}"  "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "Try-runtime peaq error!!!"
		ERROR_HAPPENED=1
	fi
fi

if [ ${ERROR_HAPPENED} -ne 1 ]; then
	echo_report "${REPORT_PATH}" "Try-runtime ${CHAIN} success!!"
fi

FINISH_DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo_report "${REPORT_PATH}" "Finish try-runtime test: From ${START_DATETIME} to ${FINISH_DATETIME}"
cat "${REPORT_PATH}" >> "${SUMMARY_PATH}"
echo_highlight "Please go to ${SUMMARY_PATH} or ${REPORT_PATH} check the report"
