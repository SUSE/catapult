#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Deploying stratos"

# save STRATOS_CHART on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n stratos-chart: "'$STRATOS_CHART'"'

helm install ./console \
    --name susecf-console \
    --namespace stratos \
    --values scf-config-values-for-stratos.yaml

bash "$ROOT_DIR"/include/wait_ns.sh stratos

helm status susecf-console | grep ui-ext

ok "Stratos deployed successfully"
