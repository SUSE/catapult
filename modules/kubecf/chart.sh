#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

rm -rf helm chart scf_chart_url suse kubecf

# our url or passed by user
# from_repo

# path
# url
if [ "$SCF_CHART" == "from_repo" ]; then
    HELM_REPO="${SCF_HELM_REPO:-https://kubernetes-charts.suse.com/}"
    HELM_REPO_NAME="${SCF_HELM_REPO_NAME:-suse}"
    info "Grabbing chart from $HELM_REPO"

    helm_init_client
    helm repo add "$HELM_REPO_NAME" $HELM_REPO
    helm repo update

    helm fetch "$HELM_REPO_NAME/kubecf"
    helm fetch "$HELM_REPO_NAME/cf-operator"
else
    if [ -z "$SCF_CHART" ]; then
        warn "No chart url given - using latest public release from GH"
        SCF_CHART=$(curl -s https://api.github.com/repos/cloudfoundry-incubator/kubecf/releases/latest | grep "browser_download_url.*bundle.*tgz" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
    fi
    if echo "$SCF_CHART" | grep -q "http"; then
        wget "$SCF_CHART" -O chart
    else
        echo "fail?"
        cp -rfv "$SCF_CHART" chart
    fi
fi

if echo "$SCF_CHART" | grep -q "tgz"; then
    if [ -f chart ]; then
        tar -xvf chart -C ./
        rm -f chart
    fi
fi

for file in *tgz; do
    tar -xvf "$file" -C ./
    rm -f "$file"
done
cp -rfv kubecf*/* ./

# save SCF_CHART on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$SCF_CHART'"'

ok "Chart uncompressed"
