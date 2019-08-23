#!/bin/bash

set -ex 

. scripts/include/common.sh

[ ! -d "scf" ] && git clone --recurse-submodules "$SCF_REPO"
pushd scf
    git checkout "$SCF_BRANCH"
    git pull
    git submodule sync --recursive && \
    git submodule update --init --recursive && \
    git submodule foreach --recursive "git checkout . && git reset --hard && git clean -dffx"

    chmod 777 -R src/uaa-fissile-release/ || true
    docker exec ${DOCKER_OPTS} \
    -ti $cluster_name-control-plane \
    /bin/bash -c 'apt-get update && apt-get install -y ruby git wget make; cd /code/scf && source .envrc && ./bin/dev/install_tools.sh && make vagrant-prep'
    cp -rfv output/helm ../
    cp -rfv output/kube ../
popd

