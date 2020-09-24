#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

helm list -A
kubectl get pods -A

info "Upgrading CFO…"

helm_upgrade cf-operator cf-operator/ \
             --namespace cf-operator \
             --set "global.singleNamespace.name=scf"

info "Wait for cf-operator to be ready"

wait_for_cf-operator

ok "cf-operator ready"

helm list -A
kubectl get pods -A

info "Upgrading KubeCF…"

if [ -n "$SCF_CHART" ]; then
# save SCF_CHART on cap-values configmap
    kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$SCF_CHART'"'
fi

helm_upgrade susecf-scf kubecf/ \
             --namespace scf \
             --values scf-config-values.yaml
sleep 10

wait_ns scf

ok "KubeCF deployment upgraded successfully"

helm list -A
kubectl get pods -A
