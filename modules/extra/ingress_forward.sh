#!/bin/bash

set -e

. ../../include/common.sh
. .envrc

debug_mode

exec kubectl port-forward -n default pod/socksproxy "${KUBEPROXY_PORT}":8000
