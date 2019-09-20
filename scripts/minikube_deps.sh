#!/bin/bash

# duplicated in s/include/common.sh, needed for bootstrapping:
export CLUSTER_NAME=${CLUSTER_NAME:-minikube}

. scripts/include/common.sh

set -Eeuxo pipefail

MINIKUBE_VERSION=latest

curl -Lo minikube https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-${OS_TYPE}-amd64
chmod +x minikube && mv minikube bin/
curl -Lo docker-machine-driver-kvm2 https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2
chmod +x docker-machine-driver-kvm2 && mv docker-machine-driver-kvm2 bin/

popd
