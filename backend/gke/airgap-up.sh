#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

export KUBECF_NAMESPACE=scf
export QUARKS_NAMESPACE=cf-operator
for ns in $KUBECF_NAMESPACE $QUARKS_NAMESPACE default; do
    kubectl create namespace $ns || true
    kubectl label namespaces --overwrite $ns airgap=true
done

gke_isolate_network 1
