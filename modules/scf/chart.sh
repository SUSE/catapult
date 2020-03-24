#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

rm -rf helm chart scf_chart_url suse kubecf

if [ -z "$SCF_CHART" ] && [ -z "$SCF_HELM_VERSION" ]; then
    warn "No chart url given - using latest public release from GH"
    if  [ "${SCF_OPERATOR}" != "true" ]; then
        SCF_CHART=$(curl -s https://api.github.com/repos/SUSE/scf/releases/latest | grep "browser_download_url.*zip" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
    else
        SCF_CHART=$(curl -s https://api.github.com/repos/cloudfoundry-incubator/kubecf/releases/latest | grep "browser_download_url.*bundle.*tgz" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
    fi
fi

if [ -n "$SCF_HELM_VERSION" ]; then
    HELM_REPO="${SCF_HELM_REPO:-https://kubernetes-charts.suse.com/}"
    HELM_REPO_NAME="${SCF_HELM_REPO_NAME:-suse}"
    info "Grabbing $SCF_HELM_VERSION from $HELM_REPO"

    helm_init_client
    helm repo add "$HELM_REPO_NAME" $HELM_REPO
    helm repo update

    helm fetch "$HELM_REPO_NAME"/cf --version $SCF_HELM_VERSION
    helm fetch "$HELM_REPO_NAME"/uaa --version $SCF_HELM_VERSION

    mkdir -p charts/helm
    tar xvf cf-*.tgz -C charts/helm
    tar xvf uaa-*.tgz -C charts/helm
    pushd charts || exit
        VERSION=$(yq r helm/cf/Chart.yaml version)
        API_VERSION=$(yq r helm/cf/Chart.yaml apiVersion)

        if [ "${API_VERSION}" == "v1" ]; then
            API_VERSION=$(yq r helm/cf/Chart.yaml scfVersion)
        fi

        if [ -z "$VERSION" ]; then
            err "No version found from the chart"
            exit 1
        fi

        if [ -z "$API_VERSION" ]; then
            err "No api version found from the chart"
            exit 1
        fi
        info "Producing bundle for $API_VERSION - $VERSION"
        tar cvzf ../scf-sle-${API_VERSION}.tgz *
        zip -r9 ../scf-sle-${API_VERSION}.zip -- *
        export SCF_CHART=$PWD/../scf-sle-${API_VERSION}.zip
    popd || exit
fi

rm -rf scf_chart_url || true

if echo "$SCF_CHART" | grep -q "http"; then
    wget "$SCF_CHART" -O chart
    echo "$SCF_CHART" > scf_chart_url
else
    cp -rfv "$SCF_CHART" chart
fi

if echo "$SCF_CHART" | grep -q "tgz"; then
    tar -xvf chart -C ./
else
    unzip -o chart
fi

if  [ "${SCF_OPERATOR}" == "true" ]; then
    if echo "$SCF_CHART" | grep -q "bundle"; then
        tar xvzf cf-operator*.tgz
        tar xvzf kubecf*.tgz
    fi
    cp -rfv kubecf*/* ./
fi

# save SCF_CHART on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$SCF_CHART'"'

ok "Chart uncompressed"
