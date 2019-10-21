#!/bin/bash

set -e

. ../../include/common.sh
. .envrc
HELM_VERSION="${HELM_VERSION:-v2.14.3}"

if [[ "$OSTYPE" == "darwin"* ]]; then
  export HELM_OS_TYPE="${HELM_OS_TYPE:-darwin-amd64}"
else
  export HELM_OS_TYPE="${HELM_OS_TYPE:-linux-amd64}"
fi

if [ ! -e "bin/helm" ]; then
curl -L https://get.helm.sh/helm-${HELM_VERSION}-${HELM_OS_TYPE}.tar.gz | tar zxf -

mv $HELM_OS_TYPE/helm bin/
mv $HELM_OS_TYPE/tiller bin/

helm version --client

ok "Deps correctly downloaded"

fi