#!/bin/bash

. "$ROOT_DIR/backend/$BACKEND/defaults.sh"
. ./defaults.sh
. ../../include/common.sh
. .envrc

if [[ "$DOWNLOAD_BINS" == "false" ]]; then
    ok "Skipping downloading deps, using host binaries"
    exit 0
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    export HELM_OS_TYPE="${HELM_OS_TYPE:-darwin-amd64}"
    export KUBECTL_OS_TYPE="${KUBECTL_OS_TYPE:-darwin}"
    export CFCLI_OS_TYPE="${CFCLI_OS_TYPE:-macosx64}"
else
    export HELM_OS_TYPE="${HELM_OS_TYPE:-linux-amd64}"
    export KUBECTL_OS_TYPE="${KUBECTL_OS_TYPE:-linux}"
    export CFCLI_OS_TYPE="${CFCLI_OS_TYPE:-linux64}"
fi

if [ ! -e "bin/helm" ]; then
    curl -L https://get.helm.sh/helm-${HELM_VERSION}-${HELM_OS_TYPE}.tar.gz | tar zxf -
    mv $HELM_OS_TYPE/helm bin/
    mv $HELM_OS_TYPE/tiller bin/
    rm -rf "$HELM_OS_TYPE"
    helm version --client
fi

if [ ! -e "bin/kubectl" ]; then
    curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${KUBECTL_OS_TYPE}/amd64/kubectl
    mv kubectl bin/
    chmod +x bin/kubectl
    kubectl version 2>&1 | grep Client || true
fi

if [ ! -e "bin/cf" ]; then
    curl -L "https://packages.cloudfoundry.org/stable?release=${CFCLI_OS_TYPE}-binary&source=github" | tar -zx
    mv cf bin/
    rm -rf "$CFCLI_OS_TYPE" LICENSE NOTICE
    chmod +x bin/cf
    cf version
fi

bazelpath=bin/bazel
if [ ! -e "$bazelpath" ]; then
    wget "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-x86_64" -O $bazelpath
    chmod +x $bazelpath
fi

ok "Deps correctly downloaded"
