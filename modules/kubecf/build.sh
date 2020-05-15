#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [ -z "$SCF_LOCAL" ]; then
    [ ! -d "scf" ] && git clone --recurse-submodules "$SCF_REPO" scf
    git reset --hard "$SCF_BRANCH"
    git submodule sync --recursive && \
    git submodule update --init --recursive && \
    git submodule foreach --recursive "git checkout . && git reset --hard && git clean -dffx"
    pushd scf || exit
else
    pushd "$SCF_LOCAL" || exit
fi

GIT_HEAD=$(git log --pretty=format:'%h' -n 1)
rm -rfv bazel-bin/deploy/helm/kubecf/* || true
bazel build //deploy/helm/kubecf
tar -xvf bazel-bin/deploy/helm/kubecf/kubecf.tgz -C "$BUILD_DIR"
SCF_CHART=kubecf-"$GIT_HEAD"
popd || exit

# save SCF_CHART on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$SCF_CHART'"'
