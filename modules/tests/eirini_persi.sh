#!/bin/bash

set -ex

. ../../include/common.sh
. .envrc

# Don't touch original copy
cp -rfv ../contrib/samples/eirini-persi-test ./

pushd eirini-persi-test

go build -o persi-test main.go

if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
    export http_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi


cf delete-service -f eirini-persi-mount || true
cf delete -f persitest || true

cf service-brokers
cf marketplace -s eirini-persi
cf enable-service-access eirini-persi
cf create-service eirini-persi default eirini-persi-mount
kubectl get pvc -n eirini || true
cf push --no-start
cf bind-service persitest eirini-persi-mount
cf start persitest
url=http://"$(cf a | grep "persitest" | awk '{ print $6 }')"
[[ $(curl "$url") == "1" ]] || exit 1
cf restage persitest
[[ $(curl "$url") == "0" ]] || exit 1
