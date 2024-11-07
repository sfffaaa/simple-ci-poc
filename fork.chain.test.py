import subprocess
from functools import wraps
from colorama import Fore, Style
from tools.src.utils import get_env, show_generate_info
from tools.src.forked_chain_utils import compose_forked_scripts_config_path
from tools.src.forked_chain_utils import compose_forked_binary_folder
from tools.src.forked_chain_utils import execute_forked_test_parachain_launch
from tools.src.utils import wait_for_parachain_ready, wait_for_doctor_ready
from tools.src.test_utils import pytest_with_runtime_module
from tools.src.constants import TARGET_WASM_PATH
from tools.src.utils import get_wasm_info
import os


def print_command(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        command = args[0] if args else kwargs.get("args", None)
        if command:
            print(f"{Fore.YELLOW}Executing command:{Style.RESET_ALL} {command}")

        return func(*args, **kwargs)
    return wrapper


subprocess.Popen = print_command(subprocess.Popen)


TARGET_CHAIN = 'peaq-dev'


def show_report(wasm_info, runtime_module_path, pytest_result, pytest_test_arguments):
    print(f'{Fore.LIGHTGREEN_EX}Wasm version{Style.RESET_ALL}: {wasm_info["version"]}')
    print(f'{Fore.LIGHTGREEN_EX}Wasm code hash{Style.RESET_ALL}: {wasm_info["code_hash"]}')
    print(f'{Fore.LIGHTGREEN_EX}Wasm full output{Style.RESET_ALL}: {wasm_info["full_output"]}')
    print(f'{Fore.LIGHTGREEN_EX}Wasm path{Style.RESET_ALL}: {runtime_module_path}')

    print(f'{Fore.LIGHTGREEN_EX}Pytest arguments{Style.RESET_ALL}: {pytest_test_arguments}')
    if pytest_result["success"]:
        print(f'{Fore.LIGHTGREEN_EX}Pytest result{Style.RESET_ALL}: {pytest_result["success"]}')
    else:
        print(f'{Fore.RED}Pytest result{Style.RESET_ALL}: {pytest_result["success"]}')


if __name__ == '__main__':
    env_dict = get_env()

    print(f"============ {Fore.GREEN}Formal build start {Style.RESET_ALL} ============")
    print('')
    show_generate_info(env_dict, show_pytest=True)

    # We have to build again...

    forked_binary_folder = compose_forked_binary_folder(TARGET_CHAIN)
    forked_config_file = compose_forked_scripts_config_path(TARGET_CHAIN)
    # execute_forked_test_parachain_launch(TARGET_CHAIN, forked_config_file, forked_binary_folder)
    # wait_for_doctor_ready(TARGET_CHAIN)
    wait_for_parachain_ready(TARGET_CHAIN)

    runtime_module_path = os.path.join(env_dict['WORK_DIRECTORY'], 'peaq-network-node', TARGET_WASM_PATH[TARGET_CHAIN])

    wasm_info = get_wasm_info(runtime_module_path)
    venv_path = env_dict['VENV_PATH']
    pytest_test_arguments = "-s tests/pallet_did_test.py -k test_did_remove"

    pytest_result = pytest_with_runtime_module(TARGET_CHAIN, env_dict, venv_path, runtime_module_path, pytest_test_arguments)

    show_generate_info(env_dict, show_pytest=True)
    show_report(wasm_info, runtime_module_path, pytest_result, pytest_test_arguments)
    if pytest_result["success"]:
        print(f"============ {Fore.GREEN}Fork test successes {Style.RESET_ALL} ============")
    else:
        print(f"============ {Fore.RED}Fork test fails {Style.RESET_ALL} ============")
