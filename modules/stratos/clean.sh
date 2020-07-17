#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

if helm_ls 2>/dev/null | grep -qi susecf-console ; then
    helm_delete susecf-console
fi
kubectl delete --ignore-not-found namespace stratos

# delete STRATOS_CHART on cap-values configmap
if [[ -n "$(kubectl get -o json -n kube-system configmap cap-values | jq -r '.data["stratos-chart"] // empty')" ]]; then
    kubectl patch -n kube-system configmap cap-values --type json -p '[{"op": "remove", "path": "/data/stratos-chart"}]'
fi

rm -rf console stratos-config-values.yaml

ok "Stratos removed"
