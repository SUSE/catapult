#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc || exit 0

# if no kubeconfig, no cf. Exit
[ -f "$KUBECONFIG" ] || exit 0

# TODO disabling for now, it blocks indefinitely here with the pvc states in
# "Terminating"
# # clean pvcs
# kubectl get -n scf pvc -o name \
#     | xargs --no-run-if-empty kubectl delete -n scf

if helm_ls 2>/dev/null | grep -qi minibroker ; then
    helm_delete minibroker --namespace minibroker
fi
if kubectl get namespaces 2>/dev/null | grep -qi minibroker ; then
    kubectl delete --ignore-not-found namespace minibroker
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

if kubectl get namespaces 2>/dev/null | grep -qi eirini ; then
    kubectl delete --ignore-not-found namespace eirini
fi
if helm_ls 2>/dev/null | grep -qi metrics-server ; then
    helm_delete metrics-server
fi

rm -rf scf-config-values.yaml chart helm kube "$CF_HOME"/.cf

rm -rf cf-operator* kubecf* assets templates Chart.yaml values.yaml Metadata.yaml \
   imagelist.txt requirements.lock  requirements.yaml

# delete SCF_CHART on cap-values configmap
if [[ -n "$(kubectl get -o json -n kube-system configmap cap-values | jq -r '.data.chart // empty')" ]]; then
    kubectl patch -n kube-system configmap cap-values --type json -p '[{"op": "remove", "path": "/data/chart"}]'
fi

# delete SCF_SERVICES on cap-values configmap
if [[ -n "$(kubectl get -o json -n kube-system configmap cap-values | jq -r '.data.services // empty')" ]]; then
    kubectl patch -n kube-system configmap cap-values --type json \
            -p '[{"op": "remove", "path": "/data/services"}]'
fi

ok "Cleaned up KubeCF from the k8s cluster"
