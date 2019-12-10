#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Upgrading stratos-metrics"

if [ -n "$METRICS_CHART" ]; then
    # save METRICS_CHART on cap-values configmap
    kubectl patch -n kube-system configmap cap-values -p $'data:\n metrics-chart: "'$METRICS_CHART'"'
fi

helm upgrade susecf-metrics ./metrics \
     --recreate-pods \
     --values scf-config-values-for-stratos.yaml \
     --values stratos-metrics-values.yaml

bash "$ROOT_DIR"/include/wait_ns.sh metrics

ok "Stratos-metrics deployment upgraded successfully"
