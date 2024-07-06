#!/bin/bash

# CHAIN_PWD="aabb" bash run.test.bash

DATETIME=$(date '+%Y-%m-%d-%H-%M')

echo ${DATETIME}

SET_DATETIME=${DATETIME} bash try-runtime.test.bash --chain krest
SET_DATETIME=${DATETIME} bash new.chain.test.bash --chain krest --test test_did_add
SET_DATETIME=${DATETIME} bash fork.chain.test.bash --chain krest --test test_did_add
SET_DATETIME=${DATETIME} bash fork.collator.test.bash --chain krest
