#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Deploying stratos"

if [[ "$HELM_VERSION" == v3* ]]; then
   kubectl create namespace "stratos"
fi
helm_install suse-console ./console \
    --namespace stratos \
    --values scf-config-values-for-stratos.yaml

wait_ns stratos

kubectl get services suse-console-ui-ext -n stratos

ok "Stratos deployed successfully"
