import subprocess
from colorama import Fore, Style
from tools.src.utils import (
    get_env,
    show_generate_info,
    build_node,
    pack_peaq_docker_image,
)
from tools.src.forked_chain_utils import execute_new_test_parachain_launch
from tools.src.forked_chain_utils import parachain_down
from tools.src.utils import wait_for_parachain_ready, wait_for_doctor_ready
from tools.src.test_utils import pytest_wo_runtime_module
from tools.src.constants import TARGET_WASM_PATH
from tools.src.utils import get_wasm_info
import os
from tools.src.utils import print_command


subprocess.Popen = print_command(subprocess.Popen)


TARGET_CHAIN = "peaq-dev"
PYTEST_ARGUMENTS = ""


def show_report(wasm_info, pytest_result, pytest_test_arguments):
    print(f'{Fore.LIGHTGREEN_EX}Wasm version{Style.RESET_ALL}: {wasm_info["version"]}')
    print(
        f'{Fore.LIGHTGREEN_EX}Wasm code hash{Style.RESET_ALL}: {wasm_info["code_hash"]}'
    )
    print(
        f'{Fore.LIGHTGREEN_EX}Wasm full output{Style.RESET_ALL}: {wasm_info["full_output"]}'
    )

    print(
        f"{Fore.LIGHTGREEN_EX}Pytest arguments{Style.RESET_ALL}: {pytest_test_arguments}"
    )
    if pytest_result["success"]:
        print(
            f'{Fore.LIGHTGREEN_EX}Pytest result{Style.RESET_ALL}: {pytest_result["success"]}'
        )
    else:
        print(f'{Fore.RED}Pytest result{Style.RESET_ALL}: {pytest_result["success"]}')


if __name__ == "__main__":
    env_dict = get_env()

    print(f"============ {Fore.GREEN}Fork test start {Style.RESET_ALL} ============")
    print("")
    show_generate_info(env_dict, show_pytest=True)

    build_node(env_dict, with_evm=False)

    pack_peaq_docker_image(env_dict)
    execute_new_test_parachain_launch(env_dict, TARGET_CHAIN)
    wait_for_doctor_ready(TARGET_CHAIN)
    wait_for_parachain_ready(TARGET_CHAIN)

    runtime_module_path = os.path.join(
        env_dict["WORK_DIRECTORY"], "peaq-network-node", TARGET_WASM_PATH[TARGET_CHAIN]
    )

    # execute_pytest
    wasm_info = get_wasm_info(runtime_module_path)
    venv_path = env_dict["VENV_PATH"]

    pytest_result = pytest_wo_runtime_module(
        TARGET_CHAIN, env_dict, venv_path, PYTEST_ARGUMENTS
    )

    parachain_down(env_dict, remove_folder=True)

    show_generate_info(env_dict, show_pytest=True)
    show_report(wasm_info, pytest_result, PYTEST_ARGUMENTS)
    if pytest_result["success"]:
        print(
            f"============ {Fore.GREEN}Fork test successes {Style.RESET_ALL} ============"
        )
    else:
        print(f"============ {Fore.RED}Fork test fails {Style.RESET_ALL} ============")
