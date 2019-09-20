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

cf push