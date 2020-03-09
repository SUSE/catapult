#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [ "$EMBEDDED_UAA" != "true" ]; then
    if helm ls 2>/dev/null | grep -qi susecf-uaa ; then
        helm_delete susecf-uaa
    fi
    if kubectl get namespaces 2>/dev/null | grep -qi uaa ; then
        kubectl delete namespace uaa
    fi
fi

if helm ls 2>/dev/null | grep -qi susecf-scf ; then
    helm_delete susecf-scf
fi

if helm ls 2>/dev/null | grep -qi cf-operator ; then
    helm_delete cf-operator
fi

if kubectl get namespaces 2>/dev/null | grep -qi scf ; then
    kubectl delete namespace scf
fi

if kubectl get namespaces 2>/dev/null | grep -qi cf-operator ; then
    kubectl delete namespace cf-operator
fi

if [[ "$ENABLE_EIRINI" == true ]] ; then
    if kubectl get namespaces 2>/dev/null | grep -qi eirini ; then
        kubectl delete namespace eirini
    fi
    if helm ls 2>/dev/null | grep -qi metrics-server ; then
        helm_delete metrics-server
    fi
fi

rm -rf scf-config-values.yaml chart helm kube "$CF_HOME"/.cf kube-ready-state-check.sh

# delete SCF_CHART on cap-values configmap
if [[ -n "$(kubectl get -o json -n kube-system configmap cap-values | jq -r '.data.chart // empty')" ]]; then
    kubectl patch -n kube-system configmap cap-values --type json -p '[{"op": "remove", "path": "/data/chart"}]'
fi

ok "Cleaned up scf from the k8s cluster"
