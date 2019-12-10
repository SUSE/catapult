#!/bin/bash

. ../../include/common.sh
. .envrc

# Don't touch original copy
cp -rfv ../contrib/samples/ticking_app ./

pushd ticking_app

go build -o log_producing_app main.go

if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

cf push
