#!/bin/bash
set -e

. ../../include/common.sh

debug_mode

if [ -z "$SCF_CHART" ]; then
    warn "No chart url given - using latest public release from GH"
    if  [ "${SCF_OPERATOR}" != "true" ]; then
        SCF_CHART=$(curl -s https://api.github.com/repos/SUSE/scf/releases/latest | grep "browser_download_url.*zip" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
    else
        SCF_CHART="https://scf-v3.s3.amazonaws.com/scf-3.0.0-8f7a71d1.tgz"
        #SCF_CHART="https://github.com/SUSE/scf/archive/v3-develop.zip"
    fi
fi

if echo "$SCF_CHART" | grep -q "http"; then
    wget "$SCF_CHART" -O chart
else
    cp -rfv "$SCF_CHART" chart
fi

if echo "$SCF_CHART" | grep -q "tgz"; then
    tar -xvf chart -C ./
else
    unzip -o chart
fi

if  [ "${SCF_OPERATOR}" == "true" ]; then
    cp -rfv scf*/* ./
fi

ok "Chart uncompressed"
