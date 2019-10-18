#!/bin/bash

set -e

. ../../include/common.sh

if [[ "$OSTYPE" == "darwin"* ]]; then
  export KIND_OS_TYPE="${KIND_OS_TYPE:-kind-darwin-amd64}"
else
  export KIND_OS_TYPE="${KIND_OS_TYPE:-kind-linux-amd64}"
fi

curl -Lo kind https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/${KIND_OS_TYPE}
chmod +x kind
mv kind bin/kind

popd

ok "Deps correctly downloaded"