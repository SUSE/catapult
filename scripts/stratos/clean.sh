#!/usr/bin/env bash

. ../include/common.sh
. .envrc

set -exuo pipefail

if helm ls 2>/dev/null | grep -qi susecf-console ; then
    helm del --purge susecf-console
fi
if kubectl get namespaces 2>/dev/null | grep -qi stratos ; then
    kubectl delete namespace stratos
fi
