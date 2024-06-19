#!/bin/bash

source _constant.bash

deactive || echo "No need to deactivate venv"
cd ${WORK_DIRECTORY}
rm -rf ${WORK_DIRECTORY}/peaq-bc-test
rm -rf ${WORK_DIRECTORY}/venv

rm -rf ${WORK_DIRECTORY}/peaq-network-node
rm -rf ${WORK_DIRECTORY}/parachain-launch
