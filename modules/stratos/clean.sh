#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

if helm ls 2>/dev/null | grep -qi susecf-console ; then
    helm del --purge susecf-console
fi
if kubectl get namespaces 2>/dev/null | grep -qi stratos ; then
    kubectl delete namespace stratos
fi

# delete STRATOS_CHART on cap-values configmap
if [[ -n "$(kubectl get -o json -n kube-system configmap cap-values | jq -r '.data["stratos-chart"] // empty')" ]]; then
    kubectl patch -n kube-system configmap cap-values --type json -p '[{"op": "remove", "path": "/data/stratos-chart"}]'
fi

rm -rf console scf-config-values-for-stratos.yaml

ok "Stratos removed"
