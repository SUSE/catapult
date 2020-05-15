#!/bin/bash

. ../../include/common.sh
. .envrc


[ ! -d "bosh-linux-stemcell-builder" ] && \
    git clone https://github.com/SUSE/bosh-linux-stemcell-builder.git

pushd bosh-linux-stemcell-builder || exit
    git checkout devel
    make all
popd || exit
