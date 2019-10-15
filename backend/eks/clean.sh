#!/usr/bin/env bash

# Requires:
# - aws credentials present

. ../../include/common.sh

set -exuo pipefail


if [ -d "$BUILD_DIR" ]; then
    . .envrc


    if [ -d "cap-terraform/eks" ]; then
        pushd cap-terraform/eks
        terraform destroy -auto-approve
        popd
        rm -rf cap-terraform
    fi

    popd
    rm -rf "$BUILD_DIR"
fi
