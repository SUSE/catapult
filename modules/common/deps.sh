#!/bin/bash

. "$ROOT_DIR/backend/$BACKEND/defaults.sh"
. ./defaults.sh
. ../../include/common.sh
. .envrc

if [[ "$OSTYPE" == "darwin"* ]]; then
    export HELM_OS_TYPE="${HELM_OS_TYPE:-darwin-amd64}"
    export KUBECTL_OS_TYPE="${KUBECTL_OS_TYPE:-darwin}"
    export CFCLI_OS_TYPE="${CFCLI_OS_TYPE:-macosx64}"
    export YAMLPATCH_OS_TYPE="${YAMLPATCH_OS_TYPE:-darwin}"
    export YQ_OS_TYPE="${YQ_OS_TYPE:-darwin_amd64}"
else
    export HELM_OS_TYPE="${HELM_OS_TYPE:-linux-amd64}"
    export KUBECTL_OS_TYPE="${KUBECTL_OS_TYPE:-linux}"
    export CFCLI_OS_TYPE="${CFCLI_OS_TYPE:-linux64}"
    export YAMLPATCH_OS_TYPE="${YAMLPATCH_OS_TYPE:-linux}"
    export YQ_OS_TYPE="${YQ_OS_TYPE:-linux_amd64}"
fi


if [[ "$DOWNLOAD_BINS" == "false" ]]; then
    ok "Skipping downloading bins, using host binaries"
else
    info "Downloading specific helm, kubectl, cf versions…"
    if [ ! -e "bin/helm" ]; then
        curl -sL https://get.helm.sh/helm-${HELM_VERSION}-${HELM_OS_TYPE}.tar.gz | tar zxf -
        mv $HELM_OS_TYPE/helm bin/
        if [ -e "$HELM_OS_TYPE/tiller" ]; then
            mv $HELM_OS_TYPE/tiller bin/
        fi
        rm -rf "$HELM_OS_TYPE"
        info "Helm version:"
        helm_info
    fi

    if [ ! -e "bin/kubectl" ]; then
        curl -sLO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${KUBECTL_OS_TYPE}/amd64/kubectl
        mv kubectl bin/
        chmod +x bin/kubectl
        info "Kubectl version:"
        kubectl version 2>&1 | grep Client || true
    fi

    if [ ! -e "bin/cf" ]; then
        curl -sL "https://packages.cloudfoundry.org/stable?release=${CFCLI_OS_TYPE}-binary&source=github" | tar -zx
        mv cf bin/
        rm -rf "$CFCLI_OS_TYPE" LICENSE NOTICE
        chmod +x bin/cf
        info "CF cli version:"
        cf version
    fi
fi


if [[ "$DOWNLOAD_CATAPULT_DEPS" == "false" ]]; then
    ok "Skipping downloading catapult dependencies, using host binaries"
else
    bazelpath=bin/bazel
    if [ ! -e "$bazelpath" ]; then
        wget "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-x86_64" -O $bazelpath
        chmod +x $bazelpath
    fi

    yamlpatchpath=bin/yaml-patch
    if [ ! -e "$yamlpatchpath" ]; then
        wget "https://github.com/krishicks/yaml-patch/releases/download/v0.0.10/yaml_patch_${YAMLPATCH_OS_TYPE}" -O $yamlpatchpath
        chmod +x $yamlpatchpath
    fi

    yqpath=bin/yq
    if [ ! -e "$yqpath" ]; then
        wget "https://github.com/mikefarah/yq/releases/download/2.4.0/yq_${YQ_OS_TYPE}" -O $yqpath
        chmod +x $yqpath
    fi
fi


ok "Deps correctly downloaded"
