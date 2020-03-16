#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Deploying stratos-metrics"

if [[ "$HELM_VERSION" == v3* ]]; then
    kubectl create namespace "stratos-metrics"
fi
helm_install susecf-metrics ./metrics \
     --namespace stratos-metrics \
     --values scf-config-values-for-metrics.yaml \
     --values stratos-metrics-values.yaml

wait_ns metrics

kubectl get service susecf-metrics-metrics-nginx --namespace stratos-metrics

ok "Stratos-metrics deployed successfully"
