#!/bin/bash
set -x

mkdir build${CLUSTER_NAME}

. scripts/include/common.sh

if [ -z "$EKCP_HOST" ]; then
    wget https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64
    mv kind-linux-amd64 kind
    chmod +x kind
fi
popd