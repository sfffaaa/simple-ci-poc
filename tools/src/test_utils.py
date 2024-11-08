import os
import subprocess


def pytest_wi_runtime_module(
    chain_name, env_dict, venv_path, runtime_module_path, pytest_test_arguments
):
    env = env_dict.copy()
    env["RUNTIME_UPGRADE_PATH"] = runtime_module_path

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
        process.wait()
        if process.returncode:
            print(f"Error: on {os.getcwd()} build failed")
            return {
                "success": False,
                "out": process.stdout,
            }
        return {
            "success": True,
            "out": process.stdout,
        }


def pytest_wo_runtime_module(chain_name, env_dict, venv_path, pytest_test_arguments):
    env = env_dict.copy()

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
        process.wait()
        if process.returncode:
            print(f"Error: on {os.getcwd()} build failed")
            return {
                "success": False,
                "out": process.stdout,
            }
        return {
            "success": True,
            "out": process.stdout,
        }
