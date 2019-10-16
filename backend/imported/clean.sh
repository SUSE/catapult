#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ../../include/common.sh

set -exuo pipefail

info "Deleting imported k8s cluster"

if [ -d "$BUILD_DIR" ]; then
    popd
    rm -rf "$BUILD_DIR"
fi
