#!/bin/bash

. ../../include/common.sh
. .envrc

info "Forwarding.. CTRL^C when you are done!"
exec kubectl port-forward -n default pod/socksproxy "${KUBEPROXY_PORT}":8000
