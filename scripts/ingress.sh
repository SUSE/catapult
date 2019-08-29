#!/bin/bash

set -ex 

. scripts/include/common.sh

kubectl apply -f ../kube/socks.yaml
echo "Now you can run: make ingress-forward &"
echo "Afterwards you can access your cluster network by setting socks5://127.0.0.1:2224 as your proxy. e.g. https_proxy=socks5://127.0.0.1:2224"