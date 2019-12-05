#!/bin/bash

. ./defaults.sh
. ../../include/common.sh

if [[ "$OSTYPE" == "darwin"* ]]; then
  export KIND_OS_TYPE="${KIND_OS_TYPE:-kind-darwin-amd64}"
else
  export KIND_OS_TYPE="${KIND_OS_TYPE:-kind-linux-amd64}"
fi

if [[ $KIND_VERSION =~ ^0\.2\.[0-9]$ ]]; then
  curl -Lo kind https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/${KIND_OS_TYPE}
else
  curl -Lo kind https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/${KIND_OS_TYPE}
fi
chmod +x kind
mv kind bin/kind

popd

ok "Deps correctly downloaded"
