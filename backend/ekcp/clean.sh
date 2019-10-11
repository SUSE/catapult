#!/bin/bash
set -x

. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
      . .envrc
      curl -X DELETE http://$EKCP_HOST/${CLUSTER_NAME}
      popd
      rm -rf "$BUILD_DIR"
fi
