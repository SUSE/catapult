#!/bin/bash

set -ex 
pushd build
export KUBECONFIG=kubeconfig
export SCF_REPO="${SCF_REPO:-https://github.com/SUSE/scf}"
export SCF_BRANCH="${SCF_BRANCH:-devel}"

[ ! -d "scf" ] && git clone --recurse-submodules "$SCF_REPO"

pushd scf
    git checkout "$SCF_BRANCH"
    git submodule update --recursive --force && git submodule foreach --recursive 'git checkout . && git clean -fdx'
    source .envrc
    make vagrant-prep
popd