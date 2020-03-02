#!/usr/bin/env bash

# Requires:
# - aws credentials present

. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
    . .envrc


    if [ -d "cap-terraform/eks" ]; then
        pushd cap-terraform/eks || exit
        terraform destroy -auto-approve
        popd || exit
        rm -rf cap-terraform
    fi

    popd || exit
    rm -rf "$BUILD_DIR"
fi
