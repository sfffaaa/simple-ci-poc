#!/bin/bash

# CHAIN_PWD="aabb" bash run.test.bash

DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo ${DATETIME}

SET_DATETIME=${DATETIME} bash evm.wasm.test.bash --chain peaq-dev
SET_DATETIME=${DATETIME} bash evm.wasm.test.bash --chain krest
SET_DATETIME=${DATETIME} bash evm.wasm.test.bash --chain peaq

SET_DATETIME=${DATETIME} bash try-runtime.test.bash --chain peaq-dev
SET_DATETIME=${DATETIME} bash try-runtime.test.bash --chain krest
SET_DATETIME=${DATETIME} bash try-runtime.test.bash --chain peaq

# SET_DATETIME=${DATETIME} bash new.chain.test.bash --chain peaq-dev --test all
# SET_DATETIME=${DATETIME} bash fork.chain.test.bash --chain peaq-dev --test all
# SET_DATETIME=${DATETIME} bash fork.collator.test.bash --chain peaq-dev
# 
# SET_DATETIME=${DATETIME} bash new.chain.test.bash --chain krest --test all
# SET_DATETIME=${DATETIME} bash fork.chain.test.bash --chain krest --test all
# SET_DATETIME=${DATETIME} bash fork.collator.test.bash --chain krest
# 
# SET_DATETIME=${DATETIME} bash new.chain.test.bash --chain peaq --test all
# SET_DATETIME=${DATETIME} bash fork.chain.test.bash --chain peaq --test all
# SET_DATETIME=${DATETIME} bash fork.collator.test.bash --chain peaq
