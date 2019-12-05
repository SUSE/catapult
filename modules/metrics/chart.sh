#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

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
rm stratos-metrics-chart

ok "Stratos-metrics chart uncompressed"
