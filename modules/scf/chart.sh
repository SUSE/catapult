#!/bin/bash
set -ex

. ../include/common.sh

if [ -z "$CHART_URL" ]; then
    echo "No chart url given - using latest public release from GH"
    if  [ "${SCF_OPERATOR}" != "true" ]; then
        CHART_URL=$(curl -s https://api.github.com/repos/SUSE/scf/releases/latest | grep "browser_download_url.*zip" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
    else
        CHART_URL="https://scf-v3.s3.amazonaws.com/scf-3.0.0-8f7a71d1.tgz"
        #CHART_URL="https://github.com/SUSE/scf/archive/v3-develop.zip"
    fi
fi

if echo "$CHART_URL" | grep -q "http"; then
    wget "$CHART_URL" -O chart
else
    cp -rfv "$CHART_URL" chart
fi

if echo "$CHART_URL" | grep -q "tgz"; then
    tar -xvf chart -C ./
else
    unzip -o chart
fi

if  [ "${SCF_OPERATOR}" == "true" ]; then
    cp -rfv scf*/* ./
fi
