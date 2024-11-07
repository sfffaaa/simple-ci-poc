import os
from tools.src.utils import get_spec_version, get_chain_version
from tools.src.constants import RPC_ENDPOINT
import subprocess


PARACHAIN_LAUNCH_FOLDER = '/home/jaypan/Work/peaq/parachain-launch'
FORKED_BINARY_FOLDER = '/home/jaypan/Work/peaq/CI/binary'
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
    forked_folder = f'{chain_name}-{version}'

    folder_path = os.path.join(FORKED_BINARY_FOLDER, forked_folder)
    if not os.path.isdir(folder_path):
        raise IOError(f"{folder_path} not exist")
    binary_path = os.path.join(folder_path, 'peaq-node')
    if not os.path.isfile(binary_path):
        raise IOError(f"{binary_path} not exist")

    return folder_path


def execute_forked_test_parachain_launch(chain_name, forked_config_file, forked_binary_folder, keep_collator=False):
    rpc_endpoint = RPC_ENDPOINT[chain_name]

    env = os.environ.copy()
    env["RPC_ENDPOINT"] = rpc_endpoint
    env["FORKED_CONFIG_FILE"] = forked_config_file
    env["DOCKER_COMPOSE_FOLDER"] = "yoyo"
    env["FORK_FOLDER"] = forked_binary_folder
    env["KEEP_COLLATOR"] = str(keep_collator).lower()
    env["KEEP_ASSET"] = str(FORK_KEEP_ASSET).lower()
    env["KEEP_PARACHAIN"] = str(FORK_KEEP_PARACHAIN).lower()

    command = 'sh -e forked.generated.sh'
    with subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=PARACHAIN_LAUNCH_FOLDER,
        env=env,
        text=True
    ) as process:
        for line in process.stdout:
            print(line, end="")
        process.wait()
        if process.returncode:
            print(f'Error: on {PARACHAIN_LAUNCH_FOLDER} build failed')
            raise IOError

        for err_str in ['not found', 'error', 'undefined']:
            if any(err_str in line.lower() for line in process.stdout):
                print(f'Error: on {PARACHAIN_LAUNCH_FOLDER} build failed')
                raise IOError
