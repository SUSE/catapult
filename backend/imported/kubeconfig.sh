#!/usr/bin/env bash

. ../../include/common.sh

set -Eexo pipefail

if [ -z "$KUBECONFIG" ] || [ ! -f "$KUBECONFIG" ]; then
    err "No KUBECONFIG given - you need to pass one!"
    exit 1
fi

cp "$KUBECONFIG" kubeconfig
