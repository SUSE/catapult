#!/usr/bin/env bash

. scripts/include/common.sh
. .envrc

set -Eeuxo pipefail

MINIKUBE_RUNTIME=${MINIKUBE_RUNTIME:-docker} #options: containerd, cri-o
if [[ "$OSTYPE" == "darwin"* ]]; then
    MINIKUBE_VM_DRIVER=virtualbox
else
    MINIKUBE_VM_DRIVER=kvm2
fi

minikube start \
         --container-runtime="$MINIKUBE_RUNTIME" \
         --vm-driver="$MINIKUBE_VM_DRIVER" \
         --bootstrapper=kubeadm

cp .kube/config kubeconfig
