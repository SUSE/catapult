#!/bin/bash

set -ex

. ../../include/common.sh
. .envrc

# save CHART_URL on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$CHART_URL'"'

if [[ $ENABLE_EIRINI == true ]] ; then
    [ ! -f "helm/cf/templates/eirini-namespace.yaml" ] && kubectl create namespace eirini
    if ! helm ls 2>/dev/null | grep -qi metrics-server ; then
        helm install stable/metrics-server --name=metrics-server \
             --set args[0]="--kubelet-preferred-address-types=InternalIP" \
             --set args[1]="--kubelet-insecure-tls"
    fi
fi

if [ "${EMBEDDED_UAA}" != "true" ] && [ "${SCF_OPERATOR}" != "true" ]; then

    helm install helm/uaa --name susecf-uaa --namespace uaa --values scf-config-values.yaml

    bash "$ROOT_DIR"/include/wait_ns.sh uaa

    SECRET=$(kubectl get pods --namespace uaa \
    -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

    CA_CERT="$(kubectl get secret "$SECRET" --namespace uaa \
    -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

    helm install helm/cf --name susecf-scf --namespace scf \
    --values scf-config-values.yaml \
    --set "secrets.UAA_CA_CERT=${CA_CERT}"

elif [ "${SCF_OPERATOR}" == "true" ]; then

    if [ -z "$OPERATOR_CHART_URL" ]; then
        info "Getting latest cf-operator chart (override with OPERATOR_CHART_URL)"
        OPERATOR_CHART_URL=$(curl -s https://api.github.com/repos/cloudfoundry-incubator/cf-operator/releases/latest | grep "browser_download_url.*tgz" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
    fi

    domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

    # SCFv3 Doesn't support to setup a cluster password yet, doing it manually.
    kubectl create namespace scf
    kubectl create secret generic -n scf scf.var-cf-admin-password --from-literal=password=$CLUSTER_PASSWORD

    info "Install cf-operator from $OPERATOR_CHART_URL"
    # Install the operator
    helm install --namespace scf \
    --name cf-operator \
    --set "provider=gke" --set "customResources.enableInstallation=true" \
    "$OPERATOR_CHART_URL"

    bash "$ROOT_DIR"/include/wait_ns.sh scf

    SCF_CHART="scf"
    if [ -d "deploy/helm/scf" ]; then
        SCF_CHART="deploy/helm/scf"
    fi

    helm upgrade scf ${SCF_CHART} \
    --install \
    --namespace scf \
    --values scf-config-values.yaml

    sleep 540
else

    helm install helm/cf --name susecf-scf --namespace scf \
    --values scf-config-values.yaml \
    --set enable.uaa=true

    bash "$ROOT_DIR"/include/wait_ns.sh uaa
fi

bash "$ROOT_DIR"/include/wait_ns.sh scf
