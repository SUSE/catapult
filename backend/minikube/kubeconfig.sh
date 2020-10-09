#!/bin/bash

. ../../include/common.sh
. .envrc

if [ ! -f kubeconfig ]; then
    cp "$KUBECFG" kubeconfig

    ok "Kubeconfig copied"
fi
