import subprocess
from colorama import Fore, Style
from tools.src.utils import get_env, show_generate_info, build_node
from tools.src.forked_chain_utils import execute_new_test_parachain_launch
from tools.src.forked_chain_utils import parachain_down
from tools.src.forked_chain_utils import evm_node_down
from tools.src.forked_chain_utils import launch_evm_node
from tools.src.utils import wait_for_parachain_ready, wait_for_doctor_ready
from tools.src.utils import wait_for_evm_node_ready
from tools.src.test_utils import check_evm_test_result_info
from tools.src.test_utils import pytest_wo_runtime_module
from tools.src.constants import TARGET_WASM_PATH
from tools.src.utils import get_wasm_info
from tools.src.utils import print_command
from tools.src.utils import pack_peaq_docker_image
from tools.src.utils import check_node_modified
from tools.src.utils import checkout_node_branch
import os


subprocess.Popen = print_command(subprocess.Popen)


TARGET_CHAIN = "peaq-dev"
OVERRIDE_RUNTIME_MODULE = ""

EVM_FOLDER = "evm"


def show_report(
        wasm_info_wo_evm, wasm_info_wi_evm,
        runtime_module_wo_evm, runtime_module_wi_evm,
        pytest_result, pytest_test_arguments,
        evm_result):

    print(f'{Fore.LIGHTGREEN_EX}Wasm without EVM version{Style.RESET_ALL}: {wasm_info_wo_evm["version"]}')
    print(
        f'{Fore.LIGHTGREEN_EX}Wasm without EVM code hash{Style.RESET_ALL}: {wasm_info_wo_evm["code_hash"]}'
    )
    print(f"{Fore.LIGHTGREEN_EX}Wasm without EVM path{Style.RESET_ALL}: {runtime_module_wo_evm}")

    print(f'{Fore.LIGHTGREEN_EX}Wasm with EVM version{Style.RESET_ALL}: {wasm_info_wi_evm["version"]}')
    print(
        f'{Fore.LIGHTGREEN_EX}Wasm with EVM code hash{Style.RESET_ALL}: {wasm_info_wi_evm["code_hash"]}'
    )
    print(f"{Fore.LIGHTGREEN_EX}Wasm with EVM path{Style.RESET_ALL}: {runtime_module_wi_evm}")

    print(
        f"{Fore.LIGHTGREEN_EX}Pytest arguments{Style.RESET_ALL}: {pytest_test_arguments}"
    )
    if pytest_result["success"]:
        print(
            f'{Fore.LIGHTGREEN_EX}Pytest result{Style.RESET_ALL}: {pytest_result["success"]}'
        )
    else:
        print(f'{Fore.RED}Pytest result{Style.RESET_ALL}: {pytest_result["success"]}')

    print(f'{Fore.LIGHTGREEN_EX}EVM test result{Style.RESET_ALL}: {evm_result}')


def force_remove_evm_folder(env):
    command = (
        f'rm -rf {os.path.join(env["WORK_DIRECTORY"], "peaq-network-node", "evm")}'
    )
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode:
        print(f'Error: on {env["WORK_DIRECTORY"]} {result.stderr}')
        print(f'However, we can ignore this error')


def copy_evm_wasm_out(env, chain_name):
    wasm_path = TARGET_WASM_PATH[chain_name]
    target_folder = os.path.join(env["WORK_DIRECTORY"], "peaq-network-node", EVM_FOLDER)
    command = f'mkdir -p {target_folder} && ' + \
        f'cp {os.path.join(env["WORK_DIRECTORY"], "peaq-network-node", wasm_path)} {target_folder}'
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode:
        print(f'Error: on {env["WORK_DIRECTORY"]} {result.stderr}')
        raise IOError
    return os.path.join(target_folder, os.path.basename(wasm_path))


if __name__ == "__main__":
    env_dict = get_env()

    print(f"============ {Fore.GREEN}EVM WASM test start {Style.RESET_ALL} ============")
    print("")
    show_generate_info(env_dict)

    # Check if the work directory has modifier
    check_node_modified(env_dict)
    checkout_node_branch(env_dict)

    # clean evm folder
    force_remove_evm_folder(env_dict)

    # Build EVM wasm
    build_node(env_dict, with_evm=True)
    runtime_module_path_wi_evm = copy_evm_wasm_out(env_dict, TARGET_CHAIN)
    wasm_info_wi_evm = get_wasm_info(runtime_module_path_wi_evm)

    # Build nornal wasm
    build_node(env_dict, with_evm=False)
    runtime_module_path_wo_evm = os.path.join(
        env_dict["WORK_DIRECTORY"], "peaq-network-node", TARGET_WASM_PATH[TARGET_CHAIN]
    )
    wasm_info_wo_evm = get_wasm_info(runtime_module_path_wo_evm)

    # Prepare the environment
    pack_peaq_docker_image(env_dict)
    execute_new_test_parachain_launch(env_dict, TARGET_CHAIN)
    wait_for_doctor_ready(TARGET_CHAIN)

    launch_evm_node(env_dict, TARGET_CHAIN, runtime_module_path_wi_evm)

    # Pack the docker image
    wait_for_parachain_ready(TARGET_CHAIN)
    wait_for_evm_node_ready(TARGET_CHAIN)

    # Start the test test_evm_rpc_identity_contract
    venv_path = env_dict["VENV_PATH"]

    pytest_evm_args = "-k test_evm_rpc_identity_contract"
    pytest_result = pytest_wo_runtime_module(
        TARGET_CHAIN, env_dict, venv_path, pytest_evm_args
    )

    # Curl the result
    evm_result = check_evm_test_result_info()

    # Stop the network
    parachain_down(env_dict, remove_folder=True)
    evm_node_down(env_dict, TARGET_CHAIN, remove_folder=True)

    show_generate_info(env_dict, show_pytest=True)
    show_report(
        wasm_info_wo_evm,
        wasm_info_wi_evm,
        runtime_module_path_wo_evm,
        runtime_module_path_wi_evm,
        pytest_result,
        pytest_evm_args,
        evm_result)
    if pytest_result["success"]:
        print(
            f"============ {Fore.GREEN}Fork test successes {Style.RESET_ALL} ============"
        )
    else:
        print(f"============ {Fore.RED}Fork test fails {Style.RESET_ALL} ============")
