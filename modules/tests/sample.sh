#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

SAMPLE_FOLDER=$(basename "$SAMPLE_APP_REPO")

[ ! -d "$SAMPLE_FOLDER" ] && git clone --recurse-submodules "$SAMPLE_APP_REPO" "$SAMPLE_FOLDER"

if [ -f "${SAMPLE_FOLDER}/gradlew" ]; then
  pushd "$SAMPLE_FOLDER"
  ./gradlew clean assemble
  popd
fi

pushd "$SAMPLE_FOLDER" || exit

if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

cf push
