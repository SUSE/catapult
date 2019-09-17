#!/bin/bash

set -ex 

. scripts/include/common.sh
. .envrc

export OPERATOR_CHART_URL="${OPERATOR_CHART_URL:-https://s3.amazonaws.com/cf-operators/release/helm-charts/cf-operator-v0.4.0%2B1.g3d277af0.tgz}"

if [[ $ENABLE_EIRINI == true ]] ; then
    [ ! -f "helm/cf/templates/eirini-namespace.yaml" ] && kubectl create namespace eirini
    helm install stable/metrics-server --name=metrics-server \
         --set args[0]="--kubelet-preferred-address-types=InternalIP" \
         --set args[1]="--kubelet-insecure-tls"
fi

if [ "${EMBEDDED_UAA}" != "true" ] && [ "${SCF_OPERATOR}" != "true" ]; then

    helm install helm/uaa --name susecf-uaa --namespace uaa --values scf-config-values.yaml

    bash ../scripts/wait_ns.sh uaa

    SECRET=$(kubectl get pods --namespace uaa \
    -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

    CA_CERT="$(kubectl get secret $SECRET --namespace uaa \
    -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

    helm install helm/cf --name susecf-scf --namespace scf \
    --values scf-config-values.yaml \
    --set "secrets.UAA_CA_CERT=${CA_CERT}"

elif [ "${SCF_OPERATOR}" == "true" ]; then

    domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

    # Install the operator
    helm install --namespace scf \
    --name cf-operator \
    --set "provider=gke" --set "customResources.enableInstallation=true" --set "features.eirini=${ENABLE_EIRINI}" \
    $OPERATOR_CHART_URL

    bash ../scripts/wait_ns.sh scf

    SCF_CHART="scf"
    if [ -d "deploy/helm/scf" ]; then
        SCF_CHART="deploy/helm/scf"
    fi

    helm upgrade scf ${SCF_CHART} \
    --install \
    --namespace scf \
    --set "system_domain=$domain"

    sleep 900

else

    helm install helm/cf --name susecf-scf --namespace scf \
    --values scf-config-values.yaml \
    --set enable.uaa=true

    bash ../scripts/wait_ns.sh uaa
fi

bash ../scripts/wait_ns.sh scf
