import os
import datetime
import subprocess
from functools import wraps
from colorama import Fore, Style


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


WASM_PATH = {
    'peaq-dev': 'target/release/wbuild/peaq-dev-runtime/peaq_dev_runtime.compact.compressed.wasm',
    'krest': 'target/release/wbuild/peaq-krest-runtime/peaq_krest_runtime.compact.compressed.wasm',
    'peaq': 'target/release/wbuild/peaq-runtime/peaq_runtime.compact.compressed.wasm'
}


def get_env():
    now_date = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
    env = os.environ
    return {
        'PEAQ_NETWORK_NODE_BRANCH': env.get('PEAQ_NETWORK_NODE_BRANCH', 'release-delegator-update'),
        'DATETIME': env.get('DATETIME', now_date),
        'WORK_DIRECTORY': os.path.expanduser(env.get('WORK_DIRECTORY', '~/Work/peaq')),
    }


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
        if process.returncode:
            print(f'Error: on {env["WORK_DIRECTORY"]} build failed')
            raise IOError


def get_wasm_info(env):
    command = f'subwasm info {env["WORK_DIRECTORY"]}/peaq-network-node/{WASM_PATH[TARGET_CHAIN]}'
    result = subprocess.run(
        command,
        shell=True,
        cwd=os.path.join(env['WORK_DIRECTORY'], 'peaq-network-node'),
        capture_output=True,
        text=True)

    if result.returncode:
        print(f'Error: on {env["WORK_DIRECTORY"]} {result.stderr}')
        raise IOError

    version = [line for line in result.stdout.split('\n') if 'Core version' in line][0].split()[-2]
    code_hash = [line for line in result.stdout.split('\n') if 'Blake2-256 hash' in line][0].split()[-1]

    return {
        'version': 'v0.0.' + version.split('-')[-1],
        'core_version': version,
        'code_hash': code_hash,
        'full_output': result.stdout
    }


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


def show_report(env, wasm_info, cp_path_info, with_evm):
    print(f'Build report for {env["PEAQ_NETWORK_NODE_BRANCH"]}')
    print(f'Build date: {env["DATETIME"]}')
    print(f'With EVM: {with_evm}')
    print(f'Wasm version: {wasm_info["version"]}')
    print(f'Wasm code hash: {wasm_info["code_hash"]}')
    print(f'Wasm full output: {wasm_info["full_output"]}')
    print(f'Wasm binary path: {cp_path_info["binary_path"]}')
    print(f'Wasm path: {cp_path_info["wasm_path"]}')


if __name__ == '__main__':
    env_dict = get_env()

    # Check if the work directory has modifier
    check_node_modified(env_dict)
    checkout_node_branch(env_dict)

    # Cargo build with evm
    build_node(env_dict, with_evm=True)
    wasm_info_wi_evm = get_wasm_info(env_dict)
    print(wasm_info_wi_evm)
    cp_path_info_wi_evm = cp_peaq_wasm_bin(env_dict, wasm_info_wi_evm, 'evm')
    print(cp_path_info_wi_evm)

    # # Cargo build without evm
    # build_node(env_dict, with_evm=False)
    # wasm_info_wo_evm = get_wasm_info(env_dict)
    # print(wasm_info_wo_evm)
    # cp_path_info_wo_evm = cp_peaq_wasm_bin(env_dict, wasm_info_wo_evm)
    # print(cp_path_info_wo_evm)

    show_report(env_dict, wasm_info_wi_evm, cp_path_info_wi_evm, with_evm=True)
    # show_report(env_dict, wasm_info_wo_evm, cp_path_info_wo_evm, with_evm=False)
