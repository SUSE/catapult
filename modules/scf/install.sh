#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
services=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["services"]')

if [[ $ENABLE_EIRINI == true ]] ; then
   # [ ! -f "helm/cf/templates/eirini-namespace.yaml" ] && kubectl create namespace eirini
    if ! helm_ls 2>/dev/null | grep -qi metrics-server ; then
        helm_install metrics-server stable/metrics-server\
             --set args[0]="--kubelet-preferred-address-types=InternalIP" \
             --set args[1]="--kubelet-insecure-tls" || true
    fi

    echo "Waiting for metrics server to come up..."
    wait_ns default
    sleep 10
fi

if [ "${EMBEDDED_UAA}" != "true" ]; then

    kubectl create namespace "uaa"
    helm_install susecf-uaa helm/uaa --namespace uaa --values scf-config-values.yaml

    wait_ns uaa
    if [ "$services" == "lb" ]; then
        external_dns_annotate_uaa uaa "$domain"
    fi

    SECRET=$(kubectl get pods --namespace uaa \
    -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

    CA_CERT="$(kubectl get secret "$SECRET" --namespace uaa \
    -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

    helm_install susecf-scf helm/cf --namespace scf \
    --values scf-config-values.yaml \
    --set "secrets.UAA_CA_CERT=${CA_CERT}"
else
    kubectl create namespace "scf"
    helm_install susecf-scf helm/cf --namespace scf \
    --values scf-config-values.yaml \
    --set enable.uaa=true

    wait_ns uaa
    if [ "$services" == "lb" ]; then
        external_dns_annotate_uaa uaa "$domain"
    fi
fi

wait_ns scf
if [ "$services" == "lb" ]; then
    external_dns_annotate_scf scf "$domain"
fi

ok "SCF deployed successfully"
