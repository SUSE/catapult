#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ../../include/common.sh

info "Deleting imported k8s cluster"

if [ -d "$BUILD_DIR" ]; then
    popd
    rm -rf "$BUILD_DIR"
fi
