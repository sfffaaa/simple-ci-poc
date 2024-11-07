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

cd "${PEAQ_NETWORK_NODE_FOLDER}" || { echo_report "${REPORT_PATH}" "Error: ${PEAQ_NETWORK_NODE_FOLDER} not found"; exit 1; }
COMMIT=$(git log -n 1 --format=%H | cut -c 1-6)
OUT_FOLDER_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}/evm.wasm
SUMMARY_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}/summary
REPORT_PATH=${OUT_FOLDER_PATH}/report.log
ERROR_HAPPENED=0
START_DATETIME=$(date '+%Y-%m-%d-%H-%M')

mkdir -p "${OUT_FOLDER_PATH}"

echo_info "Start evm.wasm.bash"

echo_highlight "Start build for the node ${COMMIT}"
cargo build --release --features on-chain-release-build | tee ${OUT_FOLDER_PATH}/build.log
echo_highlight "Finished build ${COMMIT}"

# pack image
r_pack_peaq_docker_img "latest"
r_pack_peaq_docker_img "${COMMIT}"

echo_highlight "Finished pack docker image, ${COMMIT} + latest"

# Rebuild the evm related features
cargo build --release --features "std aura evm-tracing on-chain-release-build" | tee -a "${OUT_FOLDER_PATH}/build.log"
rm -rf evm
mkdir -p evm
if [[ $CHAIN == "peaq-dev" || $CHAIN == "all" ]]; then
	mkdir -p "${PEAQ_DEV_WASM_DST_FOLDER_PATH}"
	cp "${PEAQ_DEV_ORI_EVM_WASM_PATH}" "${PEAQ_DEV_WASM_DST_FOLDER_PATH}"
elif [[ $CHAIN == "krest" || $CHAIN == "all" ]]; then
	mkdir -p "${KREST_WASM_DST_FOLDER_PATH}"
	cp "${KREST_ORI_EVM_WASM_PATH}" "${KREST_WASM_DST_FOLDER_PATH}"
elif [[ $CHAIN == "peaq" || $CHAIN == "all" ]]; then
	mkdir -p "${PEAQ_WASM_DST_FOLDER_PATH}"
	cp "${PEAQ_ORI_EVM_WASM_PATH}" "${PEAQ_WASM_DST_FOLDER_PATH}"
fi
echo_highlight "Finished copy evm wasm image, ${COMMIT} + latest"


if [[ $CHAIN == "peaq-dev" || $CHAIN == "all" ]]; then
	execute_parachain_launch "peaq-dev" "${OUT_FOLDER_PATH}"
	execute_evm_node "peaq-dev" "${PEAQ_DEV_WASM_DST_FOLDER_PATH}" "${OUT_FOLDER_PATH}"
	if ! execute_pytest "peaq-dev" "test_evm_rpc_identity_contract" "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "evm test test fail: peaq-dev test fail"
		ERROR_HAPPENED=1
	fi
	sleep 30
	
	if ! check_evm_node_run "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "evm fails: peaq-dev test fail"
		ERROR_HAPPENED=1
	fi
	reset_evm_node
fi
if [[ $CHAIN == "krest" || $CHAIN == "all" ]]; then
	execute_parachain_launch "krest" "${OUT_FOLDER_PATH}"
	execute_evm_node "krest" "${KREST_WASM_DST_FOLDER_PATH}" "${OUT_FOLDER_PATH}"
	if ! execute_pytest "krest" "test_evm_rpc_identity_contract" "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "evm wasm test fail: krest test fail"
		ERROR_HAPPENED=1
	fi
	sleep 30
	
	if ! check_evm_node_run "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "evm fails: krest test fail"
		ERROR_HAPPENED=1
	fi
	reset_evm_node
fi
if [[ $CHAIN == "peaq" || $CHAIN == "all" ]]; then
	execute_parachain_launch "peaq" "${OUT_FOLDER_PATH}"
	execute_evm_node "peaq" "${PEAQ_WASM_DST_FOLDER_PATH}" "${OUT_FOLDER_PATH}"
	
	echo_report "${REPORT_PATH}" "Sleep 10min"
	sleep 600
	if ! execute_pytest "peaq" "test_evm_rpc_identity_contract" "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "evm wasm test fail: peaq test fail"
		ERROR_HAPPENED=1
	fi
	sleep 30
	
	if ! check_evm_node_run "${OUT_FOLDER_PATH}"; then
		echo_report "${REPORT_PATH}" "evm fails: peaq test fail"
		ERROR_HAPPENED=1
	fi
	reset_evm_node
fi

if [ ${ERROR_HAPPENED} -ne 1 ]; then
	echo_report "${REPORT_PATH}" "evm wasm finish: ${CHAIN}: success!!"
fi

FINISH_DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo_report "${REPORT_PATH}" "Finish evm wasm test: From ${START_DATETIME} to ${FINISH_DATETIME}"
cat "${REPORT_PATH}" >> "${SUMMARY_PATH}"
echo_highlight "Please go to ${SUMMARY_PATH} or ${REPORT_PATH} check the report"
