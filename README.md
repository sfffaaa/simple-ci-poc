# simple-ci-poc

## Runt the CI server
1. Execute the Python server

## When python server receive a request
1. Update the peaq-bc-test's branch
2. Update the peaq-network-node's branch
3. Build the peaq-network-node
4. Pack the docker image
5. Run all test
6. Send the result to others


# How to execute??
1. bash env.setup.bash
2. bash build.setup.bash
3. bash new.chain.test.bash
4. bash fork.chain.test.bash
