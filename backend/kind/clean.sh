#!/bin/bash

. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
      info "Cleaning up $BUILD_DIR"
      . .envrc
      kind delete cluster --name="${CLUSTER_NAME}"
      popd
      rm -rf "$BUILD_DIR"
fi

ok "Cleaned up '$CLUSTER_NAME' ($BUILD_DIR)"