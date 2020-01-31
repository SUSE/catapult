#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

if helm ls 2>/dev/null | grep -qi susecf-metrics ; then
    helm del --purge susecf-metrics
fi
if kubectl get namespaces 2>/dev/null | grep -qi metrics ; then
    kubectl delete namespace metrics
fi

# delete METRICS_CHART on cap-values configmap
if [[ -n "$(kubectl get -o json -n kube-system configmap cap-values | jq -r '.data["metrics-chart"] // empty')" ]]; then
    kubectl patch -n kube-system configmap cap-values --type json -p '[{"op": "remove", "path": "/data/metrics-chart"}]'
fi

rm -rf metrics stratos-metrics-values.yaml scf-config-values-for-metrics.yaml

ok "Stratos-metrics removed"
