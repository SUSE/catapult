#!/bin/bash

# duplicated in s/include/common.sh, needed for bootstrapping:
export CLUSTER_NAME=${CLUSTER_NAME:-minikube}

. scripts/include/common.sh

set -Eeuxo pipefail

MINIKUBE_VERSION=latest

if [[ "$OSTYPE" == "darwin"* ]]; then
    MINIKUBE_BIN=minikube-darwin-amd64
else
    MINIKUBE_BIN=minikube-linux-amd64
fi

curl -Lo minikube https://storage.googleapis.com/minikube/releases/"$MINIKUBE_VERSION"/"$MINIKUBE_BIN"
chmod +x minikube && mv minikube bin/
curl -Lo docker-machine-driver-kvm2 https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2
chmod +x docker-machine-driver-kvm2 && mv docker-machine-driver-kvm2 bin/

popd
