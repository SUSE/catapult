#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

if [[ "$DOWNLOAD_CATAPULT_DEPS" == "false" ]]; then
    ok "Skipping downloading AKS deps, using host binaries"
    exit 0
fi

azclipath=bin/az
if [ ! -e "$azclipath" ]; then
    # needs gcc libffi-devel python3-devel libopenssl-devel
    curl -o install.py https://azurecliprod.blob.core.windows.net/install.py && \
        printf "y\n$(pwd)/.lib/azure-cli\n$(pwd)/bin\nY\n$(pwd)/.envrc\n" | python3 ./install.py && \
        rm ./install.py
fi
