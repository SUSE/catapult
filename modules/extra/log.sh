#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [ ! -e "bin/stern" ]; then
    wget https://github.com/wercker/stern/releases/download/"${STERN_VERSION}"/stern_"${STERN_OS_TYPE}" -O bin/stern
    chmod +x bin/stern
fi

info "stern ${STERN_ARGS} | tee log.txt"
stern ${STERN_ARGS} | tee log.txt