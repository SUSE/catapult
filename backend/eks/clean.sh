#!/usr/bin/env bash

# Requires:
# - aws credentials present

. ../../include/common.sh

set -exuo pipefail


if [ -d ../"$BUILD_DIR" ]; then
    . .envrc

    pushd cap-terraform/eks
    terraform destroy -auto-approve
    popd

    popd
    rm -rf "$BUILD_DIR"
fi
