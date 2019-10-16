#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

set -Eexuo pipefail

if helm ls 2>/dev/null | grep -qi susecf-console ; then
    helm del --purge susecf-console
fi
if kubectl get namespaces 2>/dev/null | grep -qi stratos ; then
    kubectl delete namespace stratos
fi

# delete STRATOS_CHART on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n stratos-chart: "null"'

rm -rf console scf-config-values-for-stratos.yaml
