#!/bin/bash

set -ex 

. scripts/include/common.sh
. .envrc

kubectl apply -f ../kube/socks.yaml

sleep 5

bash ../scripts/wait.sh default

echo "Now you can run: make ingress-forward &"
echo "Afterwards you can access your cluster network by setting socks5://127.0.0.1:$KUBEPROXY_PORT as your proxy. e.g. https_proxy=socks5://127.0.0.1:$KUBEPROXY_PORT"
