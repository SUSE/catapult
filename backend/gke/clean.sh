#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ../include/common.sh

set -exuo pipefail


if [ -d "$ROOT_DIR"/"$BUILD_DIR" ]; then
    . .envrc

    pushd cap-terraform/gke
    terraform destroy -auto-approve
    popd

    popd
    rm -rf "$BUILD_DIR"
fi
