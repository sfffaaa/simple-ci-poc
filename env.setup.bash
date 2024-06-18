# Setup the projects

# Check git install or not
git --version > /dev/null 2>&1 || {
	echo "Please install git"
	exit 1
}

docker --version > /dev/null 2>&1 || {
	echo "Please install docker"
	exit 1
}

docker compose version > /dev/null 2>&1 || {
	echo "Please install docker-compose"
	exit 1
}

git clone git@github.com:peaqnetwork/peaq-network-node.git
git clone git@github.com:peaqnetwork/peaq-bc-test.git
(
	git clone git@github.com:peaqnetwork/parachain-launch.git;
	cd parachain-launch;
	git checkout -b feat/simple-ci origin/feat/simple-ci
)
