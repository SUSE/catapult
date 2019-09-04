#!/bin/bash

set -ex 

. scripts/include/common.sh
. .envrc


if [[ $ENABLE_EIRINI == true ]] ; then
    kubectl create namespace eirini
    helm install stable/metrics-server --name=metrics-server \
         --set args[0]="--kubelet-preferred-address-types=InternalIP" \
         --set args[1]="--kubelet-insecure-tls"
fi

if [ "${EMBEDDED_UAA}" != "true" ]; then

    helm install helm/uaa --name susecf-uaa --namespace uaa --values scf-config-values.yaml

    bash ../scripts/wait_ns.sh uaa

    SECRET=$(kubectl get pods --namespace uaa \
    -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

    CA_CERT="$(kubectl get secret $SECRET --namespace uaa \
    -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

    helm install helm/cf --name susecf-scf --namespace scf \
    --values scf-config-values.yaml \
    --set "secrets.UAA_CA_CERT=${CA_CERT}"

else

    helm install helm/cf --name susecf-scf --namespace scf \
    --values scf-config-values.yaml \
    --set enable.uaa=true

    bash ../scripts/wait_ns.sh uaa
fi

bash ../scripts/wait_ns.sh scf
