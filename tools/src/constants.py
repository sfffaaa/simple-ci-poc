RPC_ENDPOINT = {
    "peaq-dev": "https://wss-async.agung.peaq.network",
    "krest": "https://erpc-krest.peaq.network",
    "peaq": "https://erpc-mpfn1.peaq.network",
}

WSS_ENDPOINT = {
    "peaq-dev": "wss://wss-async.agung.peaq.network",
    "krest": "wss://erpc-krest.peaq.network",
    "peaq": "wss://erpc-mpfn1.peaq.network",
}


PARACHAIN_ID = {"peaq-dev": 2000, "krest": 2241, "peaq": 3338}

PARACHAIN_LAUNCH_DOCKER_COMPOSE_CHAIN_SPEC = {
    'peaq-dev': 'dev-local-2000.json',
    'krest': 'krest-local-2241.json',
    'peaq': 'peaq-local-3338.json',
}


TARGET_WASM_PATH = {
    "peaq-dev": "target/release/wbuild/peaq-dev-runtime/peaq_dev_runtime.compact.compressed.wasm",
    "krest": "target/release/wbuild/peaq-krest-runtime/peaq_krest_runtime.compact.compressed.wasm",
    "peaq": "target/release/wbuild/peaq-runtime/peaq_runtime.compact.compressed.wasm",
}
