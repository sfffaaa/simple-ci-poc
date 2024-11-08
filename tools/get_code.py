#!/usr/bin/env python

import getpass
import argparse
from src.ase_cipher import decrypt_mnenomic
import os


CHAIN_DEC_FILE = {
    "peaq-dev": "etc/peaq-dev-dec.json",
    "peaq": "etc/peaq-dec.json",
    "krest": "etc/krest-dec.json",
}


def parse_args():
    parser = argparse.ArgumentParser(
        description="""
        decrypt need info
        For example:
            python3 get_code.py --chain peaq-dev
    """,
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("--chain", required=True, help="The chain you want to decrypt")

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    if args.chain not in CHAIN_DEC_FILE:
        raise IOError(f"Chain {args.chain} not supported")
    pswd = os.environ.get("CHAIN_PWD")
    if not pswd:
        pswd = getpass.getpass("Please input the chain password: ")

    out = decrypt_mnenomic(CHAIN_DEC_FILE[args.chain], pswd)
    print(f"{out}")
