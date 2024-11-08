import os
import subprocess


def pytest_wi_runtime_module(
    chain_name, env_dict, venv_path, runtime_module_path, pytest_test_arguments
):
    env = env_dict.copy()
    env["RUNTIME_UPGRADE_PATH"] = runtime_module_path

    output = []
    command = (
        f"source {venv_path}/bin/activate && "
        f"RUNTIME_UPGRADE_PATH={runtime_module_path} python3 -u tools/runtime_upgrade.py && "
        f"pytest {pytest_test_arguments}"
    )
    with subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=env,
        cwd=os.path.join(env_dict["WORK_DIRECTORY"], "peaq-bc-test"),
        executable="/bin/bash",
        text=True,
        bufsize=1,
    ) as process:
        for line in process.stdout:
            print(line, end="")
            output.append(line.strip())
        process.wait()
        if process.returncode:
            print(f"Error: on {os.getcwd()} build failed")
            return {
                "success": False,
                "out": '\n'.join(output),
            }
        return {
            "success": True,
            "out": '\n'.join(output),
        }


def pytest_wo_runtime_module(chain_name, env_dict, venv_path, pytest_test_arguments):
    env = env_dict.copy()

    output = []
    command = f"source {venv_path}/bin/activate && " + f"pytest {pytest_test_arguments}"
    with subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=env,
        cwd=os.path.join(env_dict["WORK_DIRECTORY"], "peaq-bc-test"),
        executable="/bin/bash",
        text=True,
        bufsize=1,
    ) as process:
        for line in process.stdout:
            print(line, end="")
            output.append(line.strip())
        process.wait()
        if process.returncode:
            print(f"Error: on {os.getcwd()} build failed")
            return {
                "success": False,
                "out": '\n'.join(output),
            }
        return {
            "success": True,
            "out": '\n'.join(output),
        }


def check_evm_test_result_info():
    import sys
    import importlib

    if "subprocess" in sys.modules:
        show_subprocess = sys.modules["subprocess"]
        del sys.modules["subprocess"]

    original_subprocess = importlib.import_module("subprocess")

    # Get current height
    command = '''curl -s http://127.0.0.1:20044 -H "Content-Type:application/json;charset=utf-8" -d \
        '{
            "jsonrpc":"2.0",
            "method":"eth_getBlockByNumber",
            "params":["latest", false],
            "id":1
         }' | jq '.result.number'
    '''
    result = show_subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
    now_block_height_hex = result.stdout.strip().replace('"', '')
    now_block_height = int(now_block_height_hex, 16)

    for i in range(0, 1000):
        if now_block_height - i < 0:
            raise IOError(f'Cannot find the debug call')

        test_block_height = now_block_height - i
        test_block_height_hex = hex(test_block_height)

        command = f'''curl -s http://127.0.0.1:20044 -H "Content-Type:application/json;charset=utf-8" -d \
            '{{
                "jsonrpc": "2.0",
                "id": 1,
                "method": "debug_traceBlockByNumber",
                "params": ["'"{test_block_height_hex}"'", {{"tracer": "callTracer"}}]
            }}' | jq '.result[0].type != null'
        '''
        result = original_subprocess.run(command, shell=True, capture_output=True, text=True)
        if result.stdout.strip() != "true":
            continue
        command = f'''curl -s http://127.0.0.1:20044 -H "Content-Type:application/json;charset=utf-8" -d \
            '{{
                "jsonrpc": "2.0",
                "id": 1,
                "method": "debug_traceBlockByNumber",
                "params": ["'"{test_block_height_hex}"'", {{"tracer": "callTracer"}}]
            }}' | jq '.result'
        '''
        result = show_subprocess.run(command, shell=True, capture_output=True, text=True)
        sys.modules["subprocess"] = show_subprocess

        if result.returncode:
            raise IOError(f'Error: on {result.stderr}')
        return result.stdout
