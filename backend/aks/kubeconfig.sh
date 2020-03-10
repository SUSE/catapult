#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh

if [ ! -f "$KUBECFG" ]; then
    err "No KUBECFG given - you need to pass one!"
    exit 1
fi

cp "$KUBECFG" kubeconfig
kubectl get nodes  > /dev/null 2>&1 || exit
ok "Kubeconfig for $BACKEND correctly imported"
