#!/bin/bash

set -ex 

. ../include/common.sh

[ ! -d "scf" ] && git clone --recurse-submodules "$SCF_REPO"
pushd scf
    git checkout "$SCF_BRANCH"
    git pull
    git submodule sync --recursive && \
    git submodule update --init --recursive && \
    git submodule foreach --recursive "git checkout . && git reset --hard && git clean -dffx"
    sed -i 's|exit 1||' make/kube-dist || true
    sed -i 's|exit 1||' make/bundle-dist || true
    docker exec ${DOCKER_OPTS} \
    -ti $CLUSTER_NAME-control-plane \
    /bin/bash -c 'apt-get update && apt-get install -y ruby git wget make; cd /code/scf && chmod -R 777 src && source .envrc && ./bin/dev/install_tools.sh && make vagrant-prep bundle-dist'
    cp -rfv output/*.zip ../
popd

unzip -o *.zip
