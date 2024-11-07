import os
from tools.src.utils import get_env, show_generate_info, get_wasm_info
import subprocess
from functools import wraps
from colorama import Fore, Style
from tools.src.constants import TARGET_WASM_PATH


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


def check_node_modified(env):
    command = 'git diff --quiet && git diff --cached --quiet'
    result = subprocess.run(
        command,
        shell=True,
        cwd=os.path.join(env_dict['WORK_DIRECTORY'], 'peaq-network-node'),
        capture_output=True,
        text=True)

    if result.returncode:
        print('The work directory has been modified. Please commit the changes before building.')
        print(f'Error: on {env_dict["WORK_DIRECTORY"]} {result.stderr}')
        raise IOError


def checkout_node_branch(env):
    command = f'git checkout {env["PEAQ_NETWORK_NODE_BRANCH"]}'
    result = subprocess.run(
        command,
        shell=True,
        cwd=os.path.join(env['WORK_DIRECTORY'], 'peaq-network-node'),
        capture_output=True,
        text=True)

    if result.returncode:
        print(f'Error: on {env["WORK_DIRECTORY"]} {result.stderr}')
        raise IOError


def build_node(env, with_evm):
    if with_evm:
        command = f'cargo build --release --features "std aura evm-tracing on-chain-release-build"'
    else:
        command = f'cargo build --release --features "on-chain-release-build"'
    with subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=os.path.join(env['WORK_DIRECTORY'], 'peaq-network-node'),
        text=True
    ) as process:
        for line in process.stdout:
            print(line, end="")
        process.wait()
        if process.returncode:
            print(f'Error: on {env["WORK_DIRECTORY"]} build failed')
            raise IOError


def cp_peaq_wasm_bin(env, wasm_info, suffix=''):
    if suffix:
        suffix = f'-{suffix}'
    command = f'python3 cp_wasm_binary.py --chain {TARGET_CHAIN} --out-version {wasm_info["version"][1:] + suffix}'
    result = subprocess.run(
        command,
        shell=True,
        cwd='tools',
        capture_output=True,
        text=True)

    if result.returncode:
        print(f'Error: on {env["WORK_DIRECTORY"]} {result.stderr}')
        raise IOError

    return {
        'wasm_path': result.stdout.split('\n')[0].split()[-1],
        'binary_path': result.stdout.split('\n')[1].split()[-1],
    }


def show_report(wasm_info, cp_path_info, with_evm):
    print(f'{Fore.LIGHTGREEN_EX}With EVM{Style.RESET_ALL}: {with_evm}')
    print(f'{Fore.LIGHTGREEN_EX}Wasm version{Style.RESET_ALL}: {wasm_info["version"]}')
    print(f'{Fore.LIGHTGREEN_EX}Wasm code hash{Style.RESET_ALL}: {wasm_info["code_hash"]}')
    print(f'{Fore.LIGHTGREEN_EX}Wasm full output{Style.RESET_ALL}: {wasm_info["full_output"]}')
    print(f'{Fore.LIGHTGREEN_EX}Wasm binary path{Style.RESET_ALL}: {cp_path_info["binary_path"]}')
    print(f'{Fore.LIGHTGREEN_EX}Wasm path{Style.RESET_ALL}: {cp_path_info["wasm_path"]}')
    print('')


if __name__ == '__main__':
    env_dict = get_env()

    print(f"============ {Fore.GREEN}Formal build start {Style.RESET_ALL} ============")
    print('')
    show_generate_info(env_dict)

    # Check if the work directory has modifier
    check_node_modified(env_dict)
    checkout_node_branch(env_dict)

    build_runtime_path = os.path.join(env_dict['WORK_DIRECTORY'], 'peaq-network-node', TARGET_WASM_PATH[TARGET_CHAIN])

    # Cargo build with evm
    build_node(env_dict, with_evm=True)
    wasm_info_wi_evm = get_wasm_info(build_runtime_path)
    cp_path_info_wi_evm = cp_peaq_wasm_bin(env_dict, wasm_info_wi_evm, 'evm')

    # # Cargo build without evm
    # build_node(env_dict, with_evm=False)
    # wasm_info_wo_evm = get_wasm_info(build_runtime_path)
    # cp_path_info_wo_evm = cp_peaq_wasm_bin(env_dict, wasm_info_wo_evm)

    show_generate_info(env_dict)
    show_report(wasm_info_wi_evm, cp_path_info_wi_evm, with_evm=True)
    # show_report(wasm_info_wo_evm, cp_path_info_wo_evm, with_evm=False)

    # Link the CI path
