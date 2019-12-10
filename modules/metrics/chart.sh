#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [ "$METRICS_CHART" = "latest" ]; then
    warn "No metrics chart url given - using latest public release from GH"
    # TODO consume chart from assets and not the github zipfile
    METRICS_CHART=$(curl -s https://api.github.com/repos/SUSE/stratos-metrics/releases/latest | grep "zipball_url" | cut -d : -f 2,3 | tr -d \" | tr -d " " | tr -d ,)
fi

if echo "$METRICS_CHART" | grep -q "http"; then
    curl -L "$METRICS_CHART" -o stratos-metrics-chart
else
    cp -rfv "$METRICS_CHART" stratos-metrics-chart
fi

# remove old uncompressed chart
rm -rf metrics

if echo "$METRICS_CHART" | grep -q "tgz"; then
    tar -xvf stratos-metrics-chart -C ./
else
    unzip -o stratos-metrics-chart
fi

# TODO consume from github assets not the github zipfile
mv SUSE-stratos-metrics-* metrics
rm stratos-metrics-chart

ok "Stratos-metrics chart uncompressed"
