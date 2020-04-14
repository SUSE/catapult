#!/usr/bin/env bash

. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
    # TODO call terraform destroy when needed
    rm -rf "$BUILD_DIR"
fi
