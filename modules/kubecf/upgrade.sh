#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Upgrading CFO…"
helm list -A

OPERATOR_DIR=cf-operator
if [ -f quarks/Chart.yaml ]; then
    OPERATOR_DIR=quarks
fi
helm_upgrade cf-operator "${OPERATOR_DIR}/" \
             --namespace cf-operator \
             --set "global.singleNamespace.name=scf"

info "Wait for cf-operator to be ready"

wait_for_cf-operator

ok "cf-operator ready"
helm list -A

info "Upgrading KubeCF…"
helm list -A

helm_upgrade susecf-scf kubecf/ \
             --namespace scf \
             --values scf-config-values.yaml
sleep 10

wait_for_kubecf

ok "KubeCF deployment upgraded successfully"
helm list -A
