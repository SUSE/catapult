#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh

if [ ! -f "$KUBECFG" ]; then
    err "No KUBECFG given - you need to pass one!"
    exit 1
fi

cp "$KUBECFG" kubeconfig
