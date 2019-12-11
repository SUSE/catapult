#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

# remove old uncompressed chart
rm -rf console

if [ "$STRATOS_CHART" = "latest" ]; then
    warn "No stratos chart url given - using latest public release from kubernetes-charts.suse.com"
    HELM_REPO="https://kubernetes-charts.suse.com/"
    HELM_REPO_NAME="suse"

    helm init --client-only
    helm repo add "$HELM_REPO_NAME" $HELM_REPO
    helm repo update
    helm fetch "$HELM_REPO_NAME"/console
    tar -xvf console-*
    rm console-*.tgz
    STRATOS_CHART_NAME=$(cat console/values.yaml | grep consoleVersion | cut -d " " -f2)
else
    if echo "$STRATOS_CHART" | grep -q "http"; then
        curl -L "$STRATOS_CHART" -o stratos-chart
    else
        cp -rfv "$STRATOS_CHART" stratos-chart
    fi

    if echo "$STRATOS_CHART" | grep -q "tgz"; then
        tar -xvf stratos-chart -C ./
    else
        unzip -o stratos-chart
    fi
    rm stratos-chart
    STRATOS_CHART_NAME="$STRATOS_CHART"
fi

# save STRATOS_CHART_NAME on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n stratos-chart: "'$STRATOS_CHART_NAME'"'

ok "Stratos chart uncompressed"
