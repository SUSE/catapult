#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [ "$METRICS_CHART" = "latest" ]; then
    warn "No stratos chart url given - using latest public release from GH"
        STRATOS_CHART=$(curl -s https://api.github.com/repos/cloudfoundry/stratos/releases/latest | grep "browser_download_url.*zip" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
fi

if echo "$STRATOS_CHART" | grep -q "http"; then
    curl -L "$STRATOS_CHART" -o stratos-chart
else
    cp -rfv "$STRATOS_CHART" stratos-chart
fi

# remove old uncompressed chart
rm -rf console

if echo "$STRATOS_CHART" | grep -q "tgz"; then
    tar -xvf stratos-chart -C ./
else
    unzip -o stratos-chart
fi
rm stratos-chart

ok "Stratos chart uncompressed"
