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
     --values scf-config-values-for-metrics.yaml \
     --values stratos-metrics-values.yaml

wait_ns metrics

ok "Stratos-metrics deployment upgraded successfully"
