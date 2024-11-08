import os
import datetime
from colorama import Fore, Style
from functools import wraps
import subprocess
import json
import time
from tools.src.constants import PARACHAIN_ID


def get_env():
    now_date = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    env = os.environ
    return {
        "PEAQ_NETWORK_NODE_BRANCH": env.get(
            "PEAQ_NETWORK_NODE_BRANCH", "release-delegator-update"
        ),
        "DATETIME": env.get("DATETIME", now_date),
        "WORK_DIRECTORY": os.path.expanduser(env.get("WORK_DIRECTORY", "~/Work/peaq")),
        "VENV_PATH": os.path.expanduser(
            env.get("VENV_PATH", "~/venv.peaq.bc.test.0.9.43")
        ),
    }


def get_git_branch(path):
    import sys
    import importlib

    if "subprocess" in sys.modules:
        temp_subprocess = sys.modules["subprocess"]
        del sys.modules["subprocess"]

    original_subprocess = importlib.import_module("subprocess")

    result = original_subprocess.run(
        "git branch --show-current",
        shell=True,
        cwd=path,
        capture_output=True,
        text=True,
    )

    sys.modules["subprocess"] = temp_subprocess
    if result.returncode:
        print(f"Error: on {path} {result.stderr}")
        raise IOError

    return result.stdout.strip()


def get_git_commit(path):
    import sys
    import importlib

    if "subprocess" in sys.modules:
        temp_subprocess = sys.modules["subprocess"]
        del sys.modules["subprocess"]

    original_subprocess = importlib.import_module("subprocess")

    result = original_subprocess.run(
        "git log -n 1 --format=%H | cut -c 1-7",
        shell=True,
        cwd=path,
        capture_output=True,
        text=True,
    )

    sys.modules["subprocess"] = temp_subprocess
    if result.returncode:
        print(f"Error: on {path} {result.stderr}")
        raise IOError

    return result.stdout.strip()


def show_generate_info(env, show_pytest=False):
    peaq_network_node_branch = get_git_branch(
        os.path.join(env["WORK_DIRECTORY"], "peaq-network-node")
    )

    print(f'{Fore.LIGHTGREEN_EX}Start date{Style.RESET_ALL}: {env["DATETIME"]}')
    print(
        f"{Fore.LIGHTGREEN_EX}simple-ci-poc branch{Style.RESET_ALL}: "
        f'{get_git_branch(os.path.join(env["WORK_DIRECTORY"], "simple-ci-poc"))}-'
        f'{get_git_commit(os.path.join(env["WORK_DIRECTORY"], "simple-ci-poc"))}'
    )

    print(
        f"{Fore.LIGHTGREEN_EX}Peaq-network-node branch{Style.RESET_ALL}: {peaq_network_node_branch}-"
        f'{get_git_commit(os.path.join(env["WORK_DIRECTORY"], "peaq-network-node"))}'
    )
    if (
        get_git_branch(os.path.join(env["WORK_DIRECTORY"], "peaq-network-node"))
        != env["PEAQ_NETWORK_NODE_BRANCH"]
    ):
        print(
            f"{Fore.RED}Error!!! The branch is not equal to the target branch{Style.RESET_ALL}"
        )
        print(f"{Fore.RED}Please check immediately{Style.RESET_ALL}")
        raise IOError
    if show_pytest:
        print(
            f"{Fore.LIGHTGREEN_EX}peaq-bc-test branch{Style.RESET_ALL}: "
            f'{get_git_branch(os.path.join(env["WORK_DIRECTORY"], "peaq-bc-test"))}-'
            f'{get_git_commit(os.path.join(env["WORK_DIRECTORY"], "peaq-bc-test"))}'
        )
        print(
            f"{Fore.LIGHTGREEN_EX}parachain-launch branch{Style.RESET_ALL}: "
            f'{get_git_branch(os.path.join(env["WORK_DIRECTORY"], "parachain-launch"))}-'
            f'{get_git_commit(os.path.join(env["WORK_DIRECTORY"], "parachain-launch"))}'
        )
        print(f'{Fore.LIGHTGREEN_EX}venv path{Style.RESET_ALL}: {env["VENV_PATH"]}')

    print("")


def get_spec_version(endpoint):
    command = (
        'curl -s -H "Content-Type: application/json" -d \'{"jsonrpc":"2.0","method":"chain_getRuntimeVersion","params":[],"id":1}\' "'
        + endpoint
        + '"'
    )
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode:
        print(
            "The work directory has been modified. Please commit the changes before building."
        )
        print(f"Error: on {result.stderr}")
        raise IOError

    return json.loads(result.stdout)["result"]["specVersion"]


def get_chain_version(version):
    return f"v0.0.{version}"


def wait_for_doctor_ready(chain_name):
    print(f"{Fore.LIGHTCYAN_EX} Sleep 90 for the checking {Style.RESET_ALL}")
    time.sleep(90)

    # Check docker ps
    result = subprocess.run(
        f"docker ps | grep parachain-{PARACHAIN_ID[chain_name]}",
        shell=True,
        check=True,
        capture_output=True,
        text=True,
    )
    if result.stderr:
        raise IOError(f"No peaq containers found. {result.stderr}")

    if result.stdout:
        print(
            f"{Fore.LIGHTGREEN_EX} Found peaq container(s): {Style.RESET_ALL} {len(result.stdout)}"
        )
        print(result.stdout)
    else:
        raise IOError("No peaq containers found. {result.stdout}")


def wait_for_parachain_ready(chain_name):
    wait_for_parachain_ready_imp(chain_name, 10044)


def wait_for_evm_node_ready(chain_name):
    wait_for_parachain_ready_imp(chain_name, 20044)


def wait_for_parachain_ready_imp(chain_name, port):
    print(
        f"{Fore.LIGHTCYAN_EX} Wait for the parachain start to genererate block {Style.RESET_ALL}"
    )
    error_count = 0
    for i in range(0, 120):
        time.sleep(6)
        result = subprocess.run(
            f'curl -H \'Content-Type: application/json\' -d \'{{"jsonrpc":"2.0","method":"chain_getHeader","params":[],"id":1}}\' http://localhost:{port}',
            shell=True,
            capture_output=True,
            text=True,
        )
        if result.returncode:
            print(f"Error: on {result.stderr}")
            error_count += 1
            if error_count == 20:
                raise IOError(f"Error: on {result.stderr}")
            continue
        if "0x0" == json.loads(result.stdout)["result"]["number"]:
            if i % 10 == 0:
                print(
                    f"{Fore.LIGHTCYAN_EX} I'm waiting {i * 6}s already {Style.RESET_ALL}"
                )
            continue
        else:
            print(
                f"{Fore.LIGHTGREEN_EX} Parachain: {chain_name} is ready {Style.RESET_ALL}"
            )
            break


def get_wasm_info(runtime_module_path):
    command = f"subwasm info {runtime_module_path}"
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode:
        print(f"Error: {result.stderr}")
        raise IOError

    version = [line for line in result.stdout.split("\n") if "Core version" in line][
        0
    ].split()[-2]
    code_hash = [
        line for line in result.stdout.split("\n") if "Blake2-256 hash" in line
    ][0].split()[-1]

    return {
        "version": "v0.0." + version.split("-")[-1],
        "core_version": version,
        "code_hash": code_hash,
        "full_output": result.stdout,
    }


def build_node(env, with_evm):
    if with_evm:
        command = f'cargo build --release --features "std aura evm-tracing on-chain-release-build"'
    else:
        command = f'cargo build --release --features "on-chain-release-build"'
    output = []
    with subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=os.path.join(env["WORK_DIRECTORY"], "peaq-network-node"),
        text=True,
    ) as process:
        for line in process.stdout:
            print(line, end="")
            output.append(line.strip())
        process.wait()
        if process.returncode:
            print(f'Error: on {env["WORK_DIRECTORY"]} build failed')
            raise IOError


def pack_peaq_docker_image(env):
    docker_tag = "peaq_para_node:latest"
    command = f"docker build -f scripts/Dockerfile.parachain-launch -t {docker_tag} ."
    output = []
    with subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=os.path.join(env["WORK_DIRECTORY"], "peaq-network-node"),
        text=True,
    ) as process:
        for line in process.stdout:
            print(line, end="")
            output.append(line.strip())
        process.wait()
        if process.returncode:
            print(f'Error: on {env["WORK_DIRECTORY"]} build failed')
            raise IOError


def print_command(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        command = args[0] if args else kwargs.get("args", None)
        if command:
            print(f"{Fore.YELLOW}Executing command:{Style.RESET_ALL} {command}")

        return func(*args, **kwargs)

    return wrapper


def check_node_modified(env_dict):
    command = "git diff --quiet && git diff --cached --quiet"
    result = subprocess.run(
        command,
        shell=True,
        cwd=os.path.join(env_dict["WORK_DIRECTORY"], "peaq-network-node"),
        capture_output=True,
        text=True,
    )

    if result.returncode:
        print(
            "The work directory has been modified. Please commit the changes before building."
        )
        print(f'Error: on {env_dict["WORK_DIRECTORY"]} {result.stderr}')
        raise IOError


def checkout_node_branch(env):
    command = f'git checkout {env["PEAQ_NETWORK_NODE_BRANCH"]}'
    result = subprocess.run(
        command,
        shell=True,
        cwd=os.path.join(env["WORK_DIRECTORY"], "peaq-network-node"),
        capture_output=True,
        text=True,
    )

    if result.returncode:
        print(f'Error: on {env["WORK_DIRECTORY"]} {result.stderr}')
        raise IOError
