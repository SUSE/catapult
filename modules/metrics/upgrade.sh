#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Upgrading stratos-metrics"

METRICS_CHART_NAME=$(cat metrics/values.yaml | grep imageTag | cut -d " " -f2)
# save METRICS_CHART on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n metrics-chart: "'$METRICS_CHART_NAME'"'

helm_upgrade susecf-metrics ./metrics \
     --namespace stratos-metrics \
     --values stratos-metrics-values.yaml

wait_ns metrics

ok "Stratos-metrics deployment upgraded successfully"
