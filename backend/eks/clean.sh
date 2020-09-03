#!/usr/bin/env bash

# Requires:
# - aws credentials present

. ./defaults.sh
. ../../include/common.sh

if [ -d "${BUILD_DIR}" ]; then
    . .envrc
    if [ -d "cap-terraform/eks" ]; then
        pushd cap-terraform/eks || exit
        terraform init
        terraform destroy -auto-approve
        popd || exit
        rm -rf cap-terraform
    fi

    popd || exit
    rm -rf "${BUILD_DIR}"
    ok "EKS cluster deleted successfully"
else
    warn "BUILD_DIR ${BUILD_DIR} not found"
fi

