#!/usr/bin/env bash

. scripts/include/common.sh
. .envrc

set -Eeuxo pipefail

# minikube uses retcodes to codify in binary the status of minikube, cluster, and kubernetes
# Eg: 7 meaning: 1 (for minikube NOK) + 2 (for cluster NOK) + 4 (for kubernetes NOK)
set +x
minikube delete || true
set -x

rm -rf "$BUILD_DIR"
