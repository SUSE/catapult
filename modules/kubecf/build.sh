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
./scripts/kubecf-build.sh
tar -xvf "$(ls -t1 output/kubecf-*.tgz | head -n 1 )" -C "$BUILD_DIR"
SCF_CHART=kubecf-"$GIT_HEAD"
popd || exit
