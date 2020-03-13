#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Deploying stratos-metrics"

helm_install susecf-metrics ./metrics \
     --namespace metrics \
     --values scf-config-values-for-metrics.yaml \
     --values stratos-metrics-values.yaml

wait_ns metrics

kubectl get service susecf-metrics-metrics-nginx --namespace metrics

ok "Stratos-metrics deployed successfully"
