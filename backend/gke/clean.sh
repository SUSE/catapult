#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ./defaults.sh
. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
    . .envrc

    pushd cap-terraform/gke || exit
    terraform init
    terraform destroy -auto-approve
    popd || exit

    rm -rf "$BUILD_DIR"
    ok "GKE cluster deleted successfully"
else
    warn "BUILD_DIR ${BUILD_DIR} not found"
fi
