#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ../../include/common.sh

set -exuo pipefail


if [ -d "$BUILD_DIR" ]; then
    . .envrc

    if [ -d "cap-terraform/caasp4-kvm" ]; then
        pushd cap-terraform/caasp4-kvm
        terraform destroy -auto-approve
        popd
    fi

    popd
    rm -rf "$BUILD_DIR"
fi
