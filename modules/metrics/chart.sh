#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

# remove old uncompressed chart
rm -rf metrics

if [ "$METRICS_CHART" = "latest" ]; then
    warn "No metrics chart url given - using latest public release from kubernetes-charts.suse.com"
    HELM_REPO="https://kubernetes-charts.suse.com/"
    HELM_REPO_NAME="suse"

    helm init --client-only
    helm repo add "$HELM_REPO_NAME" $HELM_REPO
    helm repo update
    helm fetch "$HELM_REPO_NAME"/metrics
    tar -xvf metrics-*
    rm metrics-*.tgz
    METRICS_CHART_NAME=$(cat metrics/values.yaml | grep imageTag | cut -d " " -f2)
else
    if echo "$METRICS_CHART" | grep -q "http"; then
        curl -L "$METRICS_CHART" -o stratos-metrics-chart
    else
        cp -rfv "$METRICS_CHART" stratos-metrics-chart
    fi

    if echo "$METRICS_CHART" | grep -q "tgz"; then
        tar -xvf stratos-metrics-chart -C ./
    else
        unzip -o stratos-metrics-chart
    fi
    rm stratos-metrics-chart
    METRICS_CHART_NAME="$METRICS_CHART"
fi

# save STRATOS_CHART_NAME on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n metrics-chart: "'$METRICS_CHART_NAME'"'

ok "Stratos-metrics chart uncompressed"
