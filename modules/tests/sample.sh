#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

SAMPLE_FOLDER=$(basename "$SAMPLE_APP_REPO")

[ ! -d "$SAMPLE_FOLDER" ] && git clone --recurse-submodules "$SAMPLE_APP_REPO" "$SAMPLE_FOLDER"

# if we have a java spring app we need to built it before pushing
if [ -f "${SAMPLE_FOLDER}/gradlew" ]; then
  cd "$SAMPLE_FOLDER" || return
  ./gradlew clean assemble
  cd .. || return
fi

pushd "$SAMPLE_FOLDER" || exit

if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

cf push
