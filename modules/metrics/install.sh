#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Deploying stratos-metrics"

helm install ./metrics \
     --name susecf-metrics \
     --namespace metrics \
     --values scf-config-values-for-stratos.yaml \
     --values stratos-metrics-values.yaml

bash "$ROOT_DIR"/include/wait_ns.sh metrics

kubectl get service susecf-metrics-metrics-nginx --namespace metrics

ok "Stratos-metrics deployed successfully"
