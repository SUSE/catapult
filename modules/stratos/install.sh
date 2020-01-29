#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Deploying stratos"

helm install ./console \
    --name susecf-console \
    --namespace stratos \
    --values scf-config-values-for-stratos.yaml

bash "$ROOT_DIR"/include/wait_ns.sh stratos

kubectl get services susecf-console-ui-ext -n stratos

ok "Stratos deployed successfully"
