#!/bin/bash

set -ex 
pushd build
export KUBECONFIG=kubeconfig

[ ! -d "bosh-linux-stemcell-builder" ] && git clone https://github.com/SUSE/bosh-linux-stemcell-builder.git

pushd bosh-linux-stemcell-builder
    git checkout devel
    make all
popd