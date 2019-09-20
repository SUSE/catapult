#!/bin/bash

set -ex

. scripts/include/common.sh
. .envrc



SAMPLE_APP_REPO="${SAMPLE_APP_REPO:-https://github.com/cloudfoundry-samples/cf-sample-app-nodejs}"

[ ! -d "sample" ] && git clone --recurse-submodules "$SAMPLE_APP_REPO" sample

pushd sample

if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

cf service-brokers
cf enable-service-access eirini-persi
cf create-service eirini-persi default eirini-persi-1
kubectl get pvc -n eirini
cf push persitest --no-start
cf bind-service persitest eirini-persi-1
cf start persitest