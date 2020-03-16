#!/bin/bash

. ../../include/common.sh
. .envrc

# save STRATOS_CHART on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n stratos-chart: "'$STRATOS_CHART'"'

helm_upgrade suse-console ./console \
     --namespace stratos \
     --values scf-config-values-for-stratos.yaml

wait_ns stratos

ok "Stratos deployment upgraded successfully"
