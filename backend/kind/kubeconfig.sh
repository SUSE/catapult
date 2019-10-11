#!/bin/bash
set -ex

. ../include/common.sh
. .envrc

if [ -n "$EKCP_HOST" ]; then
    curl http://$EKCP_HOST/kubeconfig/${CLUSTER_NAME} > kubeconfig
else
    cp $(kind get kubeconfig-path --name="$CLUSTER_NAME") kubeconfig
fi
