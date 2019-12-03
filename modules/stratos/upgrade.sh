#!/bin/bash

set -e

. ../../include/common.sh
. .envrc

debug_mode

if [ -n "$STRATOS_CHART" ]; then
    # save STRATOS_CHART on cap-values configmap
    kubectl patch -n kube-system configmap cap-values -p $'data:\n stratos-chart: "'$STRATOS_CHART'"'
fi

helm upgrade susecf-console ./console \
     --recreate-pods \
     --values scf-config-values-for-stratos.yaml

bash "$ROOT_DIR"/include/wait_ns.sh stratos

ok "Stratos deployment upgraded successfully"
