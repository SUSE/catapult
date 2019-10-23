#!/bin/bash

set -e

. ../../include/common.sh
. .envrc

debug_mode

kubectl apply -f "$ROOT_DIR"/kube/socks.yaml

sleep 5

bash "$ROOT_DIR"/include/wait_ns.sh default

info "Now you can run: make module-extra-ingress-forward &"
info "Afterwards you can access your cluster network by setting socks5://127.0.0.1:$KUBEPROXY_PORT as your proxy. e.g. https_proxy=socks5://127.0.0.1:$KUBEPROXY_PORT"
