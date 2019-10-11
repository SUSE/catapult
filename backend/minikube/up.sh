#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

set -Eeuxo pipefail

MINIKUBE_RUNTIME=${MINIKUBE_RUNTIME:-docker} #options: containerd, cri-o
if [[ "$OSTYPE" == "darwin"* ]]; then
    MINIKUBE_VM_DRIVER=virtualbox
else
    MINIKUBE_VM_DRIVER=kvm2
fi

minikube config set WantUpdateNotification false
minikube config set memory 8192
minikube config set cpus $(($(nproc) - 2))
minikube config set disk-size 60g

minikube start \
         --container-runtime="$MINIKUBE_RUNTIME" \
         --vm-driver="$MINIKUBE_VM_DRIVER" \
         --bootstrapper=kubeadm
