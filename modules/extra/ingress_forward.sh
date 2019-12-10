#!/bin/bash

. ../../include/common.sh
. .envrc

exec kubectl port-forward -n default pod/socksproxy "${KUBEPROXY_PORT}":8000
info "Forwarding.. CTRL^C when you are done!"
