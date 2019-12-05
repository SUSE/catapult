#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Deploying stratos-metrics"

# save METRICS_CHART on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n metrics-chart: "'$METRICS_CHART'"'

helm install ./metrics \
     --name susecf-metrics \
     --namespace metrics \
     --values scf-config-values-for-stratos.yaml \
     --values stratos-metrics-values.yaml

bash "$ROOT_DIR"/include/wait_ns.sh metrics

ok "Stratos-metrics deployed successfully"
