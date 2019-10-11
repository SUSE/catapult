#!/bin/bash

set -ex

. ../include/common.sh
. .envrc

SAMPLE_APP_REPO="${SAMPLE_APP_REPO:-https://github.com/cloudfoundry-samples/cf-sample-app-nodejs}"

# Don't touch original copy
cp -rfv ../contrib/samples/ticking_app ./

pushd ticking_app

go build -o log_producing_app main.go

if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

cf push