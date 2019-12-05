#!/bin/bash

. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
      info "Cleaning up $BUILD_DIR"
      . .envrc
      if kind get clusters | grep -qi "${CLUSTER_NAME}" ; then
          kind delete cluster --name="${CLUSTER_NAME}"
      fi
      popd
      rm -rf "$BUILD_DIR"
fi

ok "Cleaned up '$CLUSTER_NAME' ($BUILD_DIR)"