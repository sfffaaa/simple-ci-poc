import os
from tools.src.utils import get_spec_version, get_chain_version
from tools.src.constants import RPC_ENDPOINT
from tools.src.constants import PARACHAIN_ID, PARACHAIN_LAUNCH_DOCKER_COMPOSE_CHAIN_SPEC
import subprocess


PARACHAIN_LAUNCH_FOLDER = "/home/jaypan/Work/peaq/parachain-launch"
FORKED_BINARY_FOLDER = "/home/jaypan/Work/peaq/CI/binary"
PARACHAIN_LAUNCH_DOCKER_COMPOSE_FOLDER = "yoyo"
FORK_KEEP_ASSET = "true"
FORK_KEEP_PARACHAIN = "false"


def compose_forked_scripts_config_path(chain_name):
    version = get_chain_version(get_spec_version(RPC_ENDPOINT[chain_name]))

    config = f"{PARACHAIN_LAUNCH_FOLDER}/scripts/config.parachain.{chain_name}.forked.{version}.yml"
    if not os.path.isfile(config):
        raise IOError(f"{config} not exist")
    return config


def compose_forked_binary_folder(chain_name):
    version = get_chain_version(get_spec_version(RPC_ENDPOINT[chain_name]))
    forked_folder = f"{chain_name}-{version}"

    folder_path = os.path.join(FORKED_BINARY_FOLDER, forked_folder)
    if not os.path.isdir(folder_path):
        raise IOError(f"{folder_path} not exist")
    binary_path = os.path.join(folder_path, "peaq-node")
    if not os.path.isfile(binary_path):
        raise IOError(f"{binary_path} not exist")

    return folder_path


def execute_forked_test_parachain_launch(
    chain_name, forked_config_file, forked_binary_folder, keep_collator=False
):
    rpc_endpoint = RPC_ENDPOINT[chain_name]

    env = os.environ.copy()
    env["RPC_ENDPOINT"] = rpc_endpoint
    env["FORKED_CONFIG_FILE"] = forked_config_file
    env["DOCKER_COMPOSE_FOLDER"] = PARACHAIN_LAUNCH_DOCKER_COMPOSE_FOLDER
    env["FORK_FOLDER"] = forked_binary_folder
    env["KEEP_COLLATOR"] = str(keep_collator).lower()
    env["KEEP_ASSET"] = str(FORK_KEEP_ASSET).lower()
    env["KEEP_PARACHAIN"] = str(FORK_KEEP_PARACHAIN).lower()

    command = "sh -e forked.generated.sh"
    output = []
    with subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=PARACHAIN_LAUNCH_FOLDER,
        env=env,
        text=True,
    ) as process:
        for line in process.stdout:
            print(line, end="")
            output.append(line.strip())
        process.wait()
        if process.returncode:
            print(f"Error: on {PARACHAIN_LAUNCH_FOLDER} build failed")
            raise IOError

        for err_str in ["not found", "error", "undefined"]:
            if any(err_str in line.lower() for line in output):
                print(f"Error: on {PARACHAIN_LAUNCH_FOLDER} build failed")
                raise IOError


def remove_parachain_composer_folder(env):
    subprocess.run(
        f"rm -rf {PARACHAIN_LAUNCH_DOCKER_COMPOSE_FOLDER}",
        shell=True,
        capture_output=True,
        cwd=os.path.join(env["WORK_DIRECTORY"], "parachain-launch"),
        text=True,
    )


def parachain_down(env, remove_folder=True):
    if not os.path.isdir(
        os.path.join(env["WORK_DIRECTORY"], "parachain-launch", PARACHAIN_LAUNCH_DOCKER_COMPOSE_FOLDER)
    ):
        return
    output = []
    with subprocess.Popen(
        f"docker compose down -v",
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        executable="/bin/bash",
        text=True,
        cwd=os.path.join(env["WORK_DIRECTORY"], "parachain-launch", PARACHAIN_LAUNCH_DOCKER_COMPOSE_FOLDER),
    ) as process:
        for line in process.stdout:
            print(line, end="")
            output.append(line.strip())
        process.wait()
        if process.returncode:
            print(f"Error: {process.stdout}")
            print(f"But it is fine, we will continue")

        for err_str in ["not found", "error", "undefined"]:
            if any(err_str in line.lower() for line in output):
                print(f"Error: on {PARACHAIN_LAUNCH_FOLDER} build failed")
                raise IOError

    if remove_folder:
        remove_parachain_composer_folder(env)


def parachain_up(env):
    output = []
    with subprocess.Popen(
        f"docker compose up --build -d",
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        executable="/bin/bash",
        text=True,
        cwd=os.path.join(env["WORK_DIRECTORY"], "parachain-launch", PARACHAIN_LAUNCH_DOCKER_COMPOSE_FOLDER),
    ) as process:
        for line in process.stdout:
            print(line, end="")
            output.append(line.strip())
        process.wait()
        if process.returncode:
            print(f"Error: {process.stdout}")
            raise IOError

        for err_str in ["not found", "error", "undefined"]:
            if any(err_str in line.lower() for line in process.stdout):
                print(f"Error: on {PARACHAIN_LAUNCH_FOLDER} build failed")
                raise IOError


def parachain_generate(env, chain_name):
    config_file = f"ci.config/config.parachain.{chain_name}.yml"
    command = f'./bin/parachain-launch generate --config="{config_file}" --output={PARACHAIN_LAUNCH_DOCKER_COMPOSE_FOLDER}'

    output = []
    with subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        executable="/bin/bash",
        cwd=os.path.join(env["WORK_DIRECTORY"], "parachain-launch"),
        text=True,
    ) as process:
        for line in process.stdout:
            print(line, end="")
            output.append(line.strip())
        process.wait()
        if process.returncode:
            print(f"Error: on {PARACHAIN_LAUNCH_FOLDER} build failed")
            raise IOError

        for err_str in ["not found", "error", "undefined"]:
            if any(err_str in line.lower() for line in output):
                print(f"Error: on {PARACHAIN_LAUNCH_FOLDER} build failed")
                raise IOError


def execute_new_test_parachain_launch(env, chain_name):
    parachain_down(env)
    parachain_generate(env, chain_name)
    parachain_up(env)


def get_peer_id(env):
    command = f"python3 tools/get_peer_id.py --read docker --type peaq | grep Parachain | grep -oE 'Parachain Peer id: [^ ]+' | awk '{{print $NF}}'"
    output = []
    with subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        executable="/bin/bash",
        text=True,
    ) as process:
        for line in process.stdout:
            print(line, end="")
            output.append(line.strip())

        for err_str in ["not found", "error", "undefined"]:
            if any(err_str in line.lower() for line in output):
                print(f"Error: on {PARACHAIN_LAUNCH_FOLDER} build failed")
                raise IOError

        process.wait()
        if process.returncode:
            print(f"Error: on {PARACHAIN_LAUNCH_FOLDER} build failed")
            raise IOError

        return '\n'.join(output)


def fork_evm_node_start(
    env,
    parachain_id,
    parachain_config,
    relaychain_config,
    wasm_folder_path,
    parachain_bootnode,
):
    evm_chain_data_folder = os.path.join(env["WORK_DIRECTORY"], "peaq-network-node", "evm", "chain-data")
    if os.path.isdir(evm_chain_data_folder):
        subprocess.run(
            f"rm -rf {evm_chain_data_folder}",
            shell=True,
            capture_output=True,
            text=True,
        )

    cwd_path = os.path.join(env["WORK_DIRECTORY"], "peaq-network-node")
    peaq_binary_path = os.path.join(env["WORK_DIRECTORY"], "peaq-network-node", "target", "release", "peaq-node")

    command = f'''{peaq_binary_path} \
        --parachain-id "{parachain_id}" \
        --chain "{parachain_config}" \
        --port 50334 \
        --rpc-port 20044 \
        --base-path "{evm_chain_data_folder}" \
        --unsafe-rpc-external \
        --rpc-cors=all \
        --rpc-methods=Unsafe \
        --ethapi=debug,trace,txpool \
        --execution wasm \
        --wasm-runtime-overrides "{wasm_folder_path}" \
        --bootnodes "{parachain_bootnode}" \
        -- \
        --execution wasm \
        --chain "{relaychain_config}" \
        --port 50345 \
        --rpc-port 20055 \
        --unsafe-rpc-external \
        --rpc-cors=all 2>&1
    '''

    process = subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        executable="/bin/bash",
        cwd=cwd_path,
        text=True,
    )
    return process


def launch_evm_node(env, chain_name, runtime_module_path):
    wasm_folder = os.path.dirname(runtime_module_path)
    if not os.path.isdir(wasm_folder):
        raise IOError(f"{wasm_folder} not exist")

    parachain_config_file_name = PARACHAIN_LAUNCH_DOCKER_COMPOSE_CHAIN_SPEC[chain_name]
    docker_compose_folder = os.path.join(env["WORK_DIRECTORY"], "parachain-launch", PARACHAIN_LAUNCH_DOCKER_COMPOSE_FOLDER)
    parachain_config_path = os.path.join(docker_compose_folder, parachain_config_file_name)
    if not os.path.isfile(parachain_config_path):
        raise IOError(f"{parachain_config_path} not exist")

    relaychain_config_path = os.path.join(docker_compose_folder, "rococo-local.json")
    if not os.path.isfile(relaychain_config_path):
        raise IOError(f"{relaychain_config_path} not exist")

    peer_id = get_peer_id(env)
    parachain_bootnode = f"/ip4/127.0.0.1/tcp/40336/p2p/{peer_id}"

    return fork_evm_node_start(
        env,
        PARACHAIN_ID[chain_name],
        parachain_config_path,
        relaychain_config_path,
        wasm_folder,
        parachain_bootnode,
    )


def evm_node_down(env, chain_name, remove_folder=False):
    command = 'pkill peaq-node'
    subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True,
    )

    if remove_folder:
        subprocess.run(
            f"rm -rf {os.path.join(env['WORK_DIRECTORY'], 'peaq-network-node', 'evm')}",
            shell=True,
            capture_output=True,
            text=True,
        )
