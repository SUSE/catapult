#!/bin/bash
set -x
. ../include/common.sh

if [ -d "$BUILD_DIR" ]; then
      . .envrc
      if [ -n "$EKCP_HOST" ]; then
        curl -X DELETE http://$EKCP_HOST/${CLUSTER_NAME}
      else
        ./kind delete cluster --name="${CLUSTER_NAME}"
      fi
  popd

  rm -rf "$BUILD_DIR"
fi
