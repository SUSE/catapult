#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

export KUBECF_NAMESPACE=scf
export QUARKS_NAMESPACE=cf-operator
gke_isolate_network 0
