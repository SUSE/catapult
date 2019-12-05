#!/usr/bin/env bash

. ../../include/common.sh

if [ -z "$KUBECFG" ] || [ ! -f "$KUBECFG" ]; then
    err "No KUBECFG given - you need to pass one!"
    exit 1
fi

cp "$KUBECFG" kubeconfig
