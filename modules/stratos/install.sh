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

helm status susecf-console | grep ui-ext

ok "Stratos deployed successfully"
