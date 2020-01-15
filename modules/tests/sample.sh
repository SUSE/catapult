#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


[ ! -d "sample" ] && git clone --recurse-submodules "$SAMPLE_APP_REPO" sample

pushd sample

if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

cf push
