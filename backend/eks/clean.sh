#!/usr/bin/env bash

# Requires:
# - aws credentials present

. ./defaults.sh
. ../../include/common.sh

set -exuo pipefail

if [ -d "${BUILD_DIR}" ]; then
    . .envrc
    if [ -f "${TFSTATE}" ]; then
        mkdir -p cap-terraform/eks
        (cd cap-terraform/eks || exit
          unzip -o "${TFSTATE}"
        )
    fi
    if [ -d "cap-terraform/eks" ]; then
        pushd cap-terraform/eks || exit
        terraform destroy -auto-approve
        popd || exit
        rm -rf cap-terraform
    fi

    popd || exit
    rm -rf "${BUILD_DIR}"
fi

ok "EKS cluster deleted successfully"
