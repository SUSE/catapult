#!/bin/bash

set -ex 
pushd build
export KUBECONFIG=kubeconfig
export SCF_REPO="${SCF_REPO:-https://github.com/SUSE/scf}"
export SCF_BRANCH="${SCF_BRANCH:-develelop}"
cluster_name=$(./kind get clusters)
[ ! -d "scf" ] && git clone --recurse-submodules "$SCF_REPO"

pushd scf
    git checkout "$SCF_BRANCH"
    git submodule sync --recursive && git submodule update --init --recursive && git submodule foreach --recursive "git checkout . && git reset --hard && git clean -dffx"
    #git submodule update --recursive --force && git submodule foreach --recursive 'git checkout . && git clean -fdx'
    docker exec -ti $cluster_name-control-plane /bin/bash -c 'apt-get update && apt-get install wget make; cd /code/scf && source .envrc && ./bin/dev/install_tools.sh && make vagrant-prep'
    cp -rfv output/* ../
popd

