#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

STRESS_FOLDER=$(basename "$STRESS_TEST_REPO")

[ ! -d "$STRESS_FOLDER" ] && git clone --recurse-submodules "$STRESS_TEST_REPO" "$STRESS_FOLDER"

pushd "$STRESS_FOLDER" || exit

if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

./start_benchmark.sh

ok "stressbenchmark finished, results in $BUILD_DIR/$STRESS_FOLDER"
