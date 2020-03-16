#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


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

if [ "${EMBEDDED_UAA}" != "true" ] && [ "${SCF_OPERATOR}" != "true" ]; then

    kubectl create namespace "uaa"
    helm_install susecf-uaa helm/uaa --namespace uaa --values scf-config-values.yaml

    wait_ns uaa

    SECRET=$(kubectl get pods --namespace uaa \
    -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

    CA_CERT="$(kubectl get secret "$SECRET" --namespace uaa \
    -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

    helm_install susecf-scf helm/cf --namespace scf \
    --values scf-config-values.yaml \
    --set "secrets.UAA_CA_CERT=${CA_CERT}"

elif [ "${SCF_OPERATOR}" == "true" ]; then
    SCF_CHART="kubecf"
    if [ -d "deploy/helm/scf" ]; then
        SCF_CHART="deploy/helm/scf"
    fi

    if [ "$OPERATOR_CHART_URL" = latest ]; then
        info "Sourcing operator from kubecf charts"
        info "Getting latest cf-operator chart (override with OPERATOR_CHART_URL)"
        OPERATOR_CHART_URL=$(yq r $SCF_CHART/Metadata.yaml operatorChartUrl)

        # If still empty, grab latest one
        if [ "$OPERATOR_CHART_URL" = latest ]; then
         info "Fallback to use latest GH release of cf-operator"
         OPERATOR_CHART_URL=$(curl -s https://api.github.com/repos/cloudfoundry-incubator/cf-operator/releases/latest | grep "browser_download_url.*tgz" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
        fi
    fi

    info "Installing cf-operator"
    kubectl create namespace cf-operator || true


    echo "Installing CFO from: ${OPERATOR_CHART_URL}"
    # Install the operator
    helm_install cf-operator "${OPERATOR_CHART_URL}" --namespace cf-operator \
    --set "provider=gke" --set "customResources.enableInstallation=true" \
    --set "global.operator.watchNamespace=scf"

    wait_ns cf-operator
    sleep 10

    # SCFv3 Doesn't support to setup a cluster password yet, doing it manually.
    kubectl create secret generic -n scf susecf-scf.var-cf-admin-password --from-literal=password="${CLUSTER_PASSWORD}"

    helm_install susecf-scf ${SCF_CHART} \
    --namespace scf \
    --values scf-config-values.yaml

    sleep 540
else

    kubectl create namespace "scf"
    helm_install susecf-scf helm/cf --namespace scf \
    --values scf-config-values.yaml \
    --set enable.uaa=true

    wait_ns uaa
fi

wait_ns scf

ok "SCF deployed successfully"
