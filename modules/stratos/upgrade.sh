#!/bin/bash

. ../../include/common.sh
. .envrc

# save STRATOS_CHART on cap-values configmap
STRATOS_CHART_NAME=$(cat console/values.yaml | grep consoleVersion | cut -d " " -f2)
kubectl patch -n kube-system configmap cap-values -p $'data:\n stratos-chart: "'$STRATOS_CHART_NAME'"'

helm_upgrade suse-console ./console \
     --namespace stratos \
     --values scf-config-values-for-stratos.yaml

wait_ns stratos

ok "Stratos deployment upgraded successfully"
