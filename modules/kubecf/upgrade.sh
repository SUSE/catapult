#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [ -n "$SCF_CHART" ]; then
# save SCF_CHART on cap-values configmap
    kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$SCF_CHART'"'
fi

helm_upgrade susecf-scf kubecf/ \
             --namespace scf \
             --values scf-config-values.yaml
sleep 10

wait_ns scf

ok "SCF deployment upgraded successfully"
