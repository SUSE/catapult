#!/usr/bin/env bash

. ../../include/common.sh


if [ -d "$BUILD_DIR" ]; then
    . .envrc
    # minikube uses retcodes to codify in binary the status of minikube, cluster, and kubernetes
    # Eg: 7 meaning: 1 (for minikube NOK) + 2 (for cluster NOK) + 4 (for kubernetes NOK)
    set +x
    minikube delete --profile "$CLUSTER_NAME" || true
    set -x
    popd || exit

    rm -rf "$BUILD_DIR"
fi
