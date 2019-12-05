#!/bin/bash

. ../../include/common.sh
. .envrc


if [ -z "$SCF_CHART" ] && [ -z "$SCF_HELM_VERSION" ]; then
    warn "No chart url given - using latest public release from GH"
    if  [ "${SCF_OPERATOR}" != "true" ]; then
        SCF_CHART=$(curl -s https://api.github.com/repos/SUSE/scf/releases/latest | grep "browser_download_url.*zip" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
    else
        SCF_CHART="https://scf-v3.s3.amazonaws.com/scf-3.0.0-8f7a71d1.tgz"
        #SCF_CHART="https://github.com/SUSE/scf/archive/v3-develop.zip"
    fi
fi

if [ -n "$SCF_HELM_VERSION" ]; then
    HELM_VERSION="$SCF_HELM_VERSION"
    HELM_REPO="${SCF_HELM_REPO:-https://kubernetes-charts.suse.com/}"
    HELM_REPO_NAME="${SCF_HELM_REPO_NAME:-suse}"
    info "Grabbing $SCF_HELM_VERSION from $HELM_REPO"

    helm init --client-only
    helm repo add "$HELM_REPO_NAME" $HELM_REPO
    helm repo update

    if [ -n "$HELM_VERSION" ]; then

        helm fetch "$HELM_REPO_NAME"/cf --version $HELM_VERSION
        helm fetch "$HELM_REPO_NAME"/uaa --version $HELM_VERSION

    else

        helm fetch "$HELM_REPO_NAME"/cf
        helm fetch "$HELM_REPO_NAME"/uaa

    fi

    # FIXME: Platform hardcoded for now - should we have a global deps step?
    [ ! -e "bin/yq" ] && wget https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64 -O bin/yq && chmod +x bin/yq

    mkdir -p charts/helm
    tar xvf cf-*.tgz -C charts/helm
    tar xvf uaa-*.tgz -C charts/helm
    pushd charts
        VERSION=$(../bin/yq r helm/cf/Chart.yaml version)
        API_VERSION=$(../bin/yq r helm/cf/Chart.yaml apiVersion)

        if [ "${API_VERSION}" == "v1" ]; then
            API_VERSION=$(../bin/yq r helm/cf/Chart.yaml scfVersion)
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
    popd
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
    cp -rfv kubecf*/* ./
fi

ok "Chart uncompressed"
