#!/bin/bash

source _constant.bash

BINARY_FOLDER="/home/jaypan/Work/peaq/CI/binary"


show_help() {
    echo "Usage: $0 [options]"
    echo "Usage: ./forkchain.test.bash --chain peaq-dev --test all"
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
OUT_FOLDER_PATH=${RESULT_PATH}/${DATETIME}.${COMMIT}."${TEST_MODULE}"

mkdir -p ${OUT_FOLDER_PATH}

# start build
echo_highlight "Start build for the node ${COMMIT}"
cargo build --release | tee ${OUT_FOLDER_PATH}/build.log
echo_highlight "Finished build ${COMMIT}"


# we don't need to pack image
if [[ $CHAIN == "peaq-dev" ]]; then
	FORKED_CONFIG_FILE="scripts/config.parachain.peaq-dev.forked.v0.0.17.yml" \
	RPC_ENDPOINT="https://rpcpc1-qa.agung.peaq.network" \
	DOCKER_COMPOSE_FOLDER="yoyo" \
	FORK_FOLDER="/home/jaypan/Work/peaq/fork-test/fork-binary/peaq-dev-v0.0.17" \
	KEEP_COLLATOR="false" \
	KEEP_ASSET="true" \
	KEEP_PARACHAIN="false" \
	sh -e -x forked.generated.sh

	execute_forked_chain_launch "peaq-dev" ${OUT_FOLDER_PATH}
	execute_pytest "peaq-dev" ${TEST_MODULE} ${OUT_FOLDER_PATH}
	exit 0
fi

# if [[ $CHAIN == "krest" ]]; then
# 	execute_parachain_launch "krest" ${OUT_FOLDER_PATH}
# 	execute_pytest "krest" ${TEST_MODULE} ${OUT_FOLDER_PATH}
# 	exit 0
# fi
# if [[ $CHAIN == "peaq" ]]; then
# 	execute_parachain_launch "peaq" ${OUT_FOLDER_PATH}
# 	execute_pytest "peaq" ${TEST_MODULE} ${OUT_FOLDER_PATH}
# 	exit 0
# fi
# if [[ $CHAIN == "all" ]]; then
# 	execute_parachain_launch "peaq-dev" ${OUT_FOLDER_PATH}
# 	execute_pytest "peaq-dev" ${TEST_MODULE} ${OUT_FOLDER_PATH}
# 	execute_parachain_launch "krest" ${OUT_FOLDER_PATH}
# 	execute_pytest "krest" ${TEST_MODULE} ${OUT_FOLDER_PATH}
# 	execute_parachain_launch "peaq" ${OUT_FOLDER_PATH}
# 	execute_pytest "peaq" ${TEST_MODULE} ${OUT_FOLDER_PATH}
# 	exit 0
# fi

FINISH_DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo_highlight "Finish forked chain test: From ${DATETIME} to ${FINISH_DATETIME}"
