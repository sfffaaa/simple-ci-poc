#!/bin/bash

source _constant.bash
source _tryruntime.bash

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

cd ${PEAQ_NETWORK_NODE_FOLDER}
COMMIT=`git log -n 1 --format=%H | cut -c 1-6`
OUT_FOLDER_PATH=${RESULT_PATH}/try-runtime/${DATETIME}.${COMMIT}."${TEST_MODULE}"
mkdir -p ${OUT_FOLDER_PATH}

echo_highlight "Start build for the node ${COMMIT}"
cargo_build "--features=try-runtime" 2>&1 | tee ${OUT_FOLDER_PATH}/build.log
echo_highlight "Finished build ${COMMIT}"

if [[ $CHAIN == "peaq-dev" || $CHAIN == "all" ]]; then
	try_runtime_test "peaq-dev" ${PEAQ_DEV_RPC_ENDPOINT} ${PEAQ_DEV_RUNTIME_MODULE_PATH}  ${OUT_FOLDER_PATH}
	if [ $? -ne 0 ]; then
		echo_error "Try-runtime peaq-dev error!!!"
	fi
fi
if [[ $CHAIN == "krest" || $CHAIN == "all" ]]; then
	try_runtime_test "krest" ${KREST_RPC_ENDPOINT} ${KREST_RUNTIME_MODULE_PATH}  ${OUT_FOLDER_PATH}
	if [ $? -ne 0 ]; then
		echo_error "Try-runtime krest error!!!"
	fi
fi
if [[ $CHAIN == "peaq" || $CHAIN == "all" ]]; then
	try_runtime_test "peaq" ${PEAQ_RPC_ENDPOINT} ${PEAQ_RUNTIME_MODULE_PATH}  ${OUT_FOLDER_PATH}
	if [ $? -ne 0 ]; then
		echo_error "Try-runtime peaq error!!!"
	fi
fi

FINISH_DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo_highlight "Finish try-runtime test: From ${DATETIME} to ${FINISH_DATETIME}"
