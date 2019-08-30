#!/bin/bash
set -x

# duplicated in s/include/common.sh, needed for bootstrapping:
export cluster_name=${CLUSTER_NAME:-kind}
export BUILD_DIR=build${cluster_name}

mkdir "$BUILD_DIR"

. scripts/include/common.sh

if [ -z "$EKCP_HOST" ]; then
    wget https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64
    mv kind-linux-amd64 kind
    chmod +x kind
fi
popd
