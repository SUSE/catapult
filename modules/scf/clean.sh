#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc || exit 0

# if no kubeconfig, no cf. Exit
[ -f "$KUBECONFIG" ] || exit 0

if [ "$EMBEDDED_UAA" != "true" ]; then
    if helm_ls 2>/dev/null | grep -qi susecf-uaa ; then
        helm_delete susecf-uaa --namespace uaa
    fi
    if kubectl get namespaces 2>/dev/null | grep -qi uaa ; then
        kubectl delete --ignore-not-found namespace uaa
    fi
fi

if helm_ls 2>/dev/null | grep -qi susecf-scf ; then
    helm_delete susecf-scf --namespace scf
fi
if kubectl get namespaces 2>/dev/null | grep -qi scf ; then
    kubectl delete --ignore-not-found namespace scf
fi

if kubectl get psp 2>/dev/null | grep -qi susecf-scf ; then
    kubectl delete --ignore-not-found psp susecf-scf-default
fi

if helm_ls 2>/dev/null | grep -qi cf-operator ; then
    helm_delete cf-operator --namespace cf-operator
fi
if kubectl get namespaces 2>/dev/null | grep -qi cf-operator ; then
    kubectl delete --ignore-not-found namespace cf-operator
fi

if [[ "$ENABLE_EIRINI" == true ]] ; then
    if kubectl get namespaces 2>/dev/null | grep -qi eirini ; then
        kubectl delete --ignore-not-found namespace eirini
    fi
    if helm_ls 2>/dev/null | grep -qi metrics-server ; then
        helm_delete metrics-server
    fi
fi

rm -rf scf-config-values.yaml chart helm kube "$CF_HOME"/.cf kube-ready-state-check.sh

ok "Cleaned up scf from the k8s cluster"
