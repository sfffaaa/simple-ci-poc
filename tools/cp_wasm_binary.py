import argparse
import os

# flake8: noqa: E501


SOURCE_FOLDER = "/home/jaypan/Work/peaq/peaq-network-node"
OUT_BINARY_FOLDER = "/home/jaypan/PublicSMB/peaq-node-binary"
OUT_WASM_FOLDER = "/home/jaypan/PublicSMB/peaq-node-wasm"
FORKED_FOLDER = "/home/jaypan/Work/peaq/fork-test/fork-binary"


def parse_args():
    parser = argparse.ArgumentParser(
        description="""
        copy wasm/binary to PublicSMB and forked folder.
        For example: --chain peaq --out-version 0.0.3
        """
    )
    parser.add_argument("--chain", required=True, help="chain name")
    parser.add_argument("--out-version", required=True, help="output version")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    runtime_folder = ""
    if args.chain == "agung":
        wasm_folder = "peaq-agung-runtime"
    elif args.chain == "peaq":
        wasm_folder = "peaq-runtime"
    elif args.chain == "peaq-dev":
        wasm_folder = "peaq-dev-runtime"
    elif args.chain == "krest":
        wasm_folder = "peaq-krest-runtime"
    else:
        raise ValueError(f"Invalid chain name, {args.chain}")

    if not args.out_version[0].isdigit():
        raise IOError(f"Invalid output version, {args.out_version}")

    wasm_name = f"{wasm_folder}.compact.compressed.wasm".replace("-", "_")
    wasm_src = f"{SOURCE_FOLDER}/target/release/wbuild/{wasm_folder}/{wasm_name}"
    wasm_dst = f"{OUT_WASM_FOLDER}/{wasm_name}.{args.chain}.v{args.out_version}"
    cmd = f"cp {wasm_src} {wasm_dst}"
    print(cmd)
    os.system(cmd)

    binary_name = "peaq-node"
    binary_src = f"{SOURCE_FOLDER}/target/release/{binary_name}"
    binary_dst = f"{OUT_BINARY_FOLDER}/{binary_name}.{args.chain}.v{args.out_version}"
    cmd = f"cp {binary_src} {binary_dst}"
    print(cmd)
    os.system(cmd)

    forked_src = binary_src
    forked_folder = f"{FORKED_FOLDER}/{args.chain}-v{args.out_version}"
    forked_dst = f"{forked_folder}"

    print(f"forked_folder: {forked_folder}")
    os.makedirs(forked_folder, exist_ok=True)
    cmd = f"cp {binary_src} {forked_dst}"
    print(cmd)
    os.system(cmd)
