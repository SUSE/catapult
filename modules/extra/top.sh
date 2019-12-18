#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [ ! -e "bin/k9s" ]; then
    wget https://github.com/derailed/k9s/releases/download/"${K9S_VERSION}"/k9s_"${K9S_VERSION}"_"${K9S_OS_TYPE}.tar.gz" -O k9s.tar.gz
    tar -xvf k9s.tar.gz -C bin/
    rm -rfv k9s.tar.gz
    chmod +x bin/k9s
fi

k9s -n scf