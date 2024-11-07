import subprocess
from functools import wraps
from colorama import Fore, Style
from tools.src.utils import get_env, show_generate_info, build_node
from tools.src.forked_chain_utils import compose_forked_scripts_config_path
from tools.src.forked_chain_utils import compose_forked_binary_folder
from tools.src.forked_chain_utils import execute_forked_test_parachain_launch
from tools.src.utils import wait_for_parachain_ready, wait_for_doctor_ready
from tools.src.test_utils import pytest_wi_runtime_module
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
OVERRIDE_RUNTIME_MODULE = ''
PYTEST_ARGUMENTS = ""


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

    forked_binary_folder = compose_forked_binary_folder(TARGET_CHAIN)
    forked_config_file = compose_forked_scripts_config_path(TARGET_CHAIN)

    if not OVERRIDE_RUNTIME_MODULE:
        build_node(env_dict, with_evm=False)

    execute_forked_test_parachain_launch(TARGET_CHAIN, forked_config_file, forked_binary_folder)
    wait_for_doctor_ready(TARGET_CHAIN)
    wait_for_parachain_ready(TARGET_CHAIN)

    if OVERRIDE_RUNTIME_MODULE:
        runtime_module_path = OVERRIDE_RUNTIME_MODULE
    else:
        runtime_module_path = os.path.join(env_dict['WORK_DIRECTORY'], 'peaq-network-node', TARGET_WASM_PATH[TARGET_CHAIN])
    if not os.path.exists(runtime_module_path):
        raise FileNotFoundError(f"Runtime module not found: {runtime_module_path}")

    wasm_info = get_wasm_info(runtime_module_path)
    venv_path = env_dict['VENV_PATH']

    pytest_result = pytest_wi_runtime_module(TARGET_CHAIN, env_dict, venv_path, runtime_module_path, PYTEST_ARGUMENTS)

    show_generate_info(env_dict, show_pytest=True)
    show_report(wasm_info, runtime_module_path, pytest_result, PYTEST_ARGUMENTS)
    if pytest_result["success"]:
        print(f"============ {Fore.GREEN}Fork test successes {Style.RESET_ALL} ============")
    else:
        print(f"============ {Fore.RED}Fork test fails {Style.RESET_ALL} ============")
