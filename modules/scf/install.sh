#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [[ $ENABLE_EIRINI == true ]] ; then
   # [ ! -f "helm/cf/templates/eirini-namespace.yaml" ] && kubectl create namespace eirini
    if ! helm ls 2>/dev/null | grep -qi metrics-server ; then
        helm install stable/metrics-server --name=metrics-server \
             --set args[0]="--kubelet-preferred-address-types=InternalIP" \
             --set args[1]="--kubelet-insecure-tls" || true
    fi

    echo "Waiting for metrics server to come up..."
    bash "$ROOT_DIR"/include/wait_ns.sh default
    sleep 10
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
    SCF_CHART="kubecf"
    if [ -d "deploy/helm/scf" ]; then
        SCF_CHART="deploy/helm/scf"
    fi

    if [ "$OPERATOR_CHART_URL" = latest ]; then
        info "Sourcing operator from kubecf charts"
        # FIXME: Platform dipendent for now
        info "Getting latest cf-operator chart (override with OPERATOR_CHART_URL)"
        [ ! -e "bin/yq" ] && wget https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64 -O bin/yq && chmod +x bin/yq

        OPERATOR_CHART_URL=$(yq r $SCF_CHART/Metadata.yaml operatorChartUrl)

        # If still empty, grab latest one
        if [ "$OPERATOR_CHART_URL" = latest ]; then
         info "Fallback to use latest GH release of cf-operator"
         OPERATOR_CHART_URL=$(curl -s https://api.github.com/repos/cloudfoundry-incubator/cf-operator/releases/latest | grep "browser_download_url.*tgz" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
        fi
    fi

    domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

    info "Installing cf-operator"
    # SCFv3 Doesn't support to setup a cluster password yet, doing it manually.
    kubectl create namespace scf || true
    kubectl create secret generic -n scf susecf-scf.var-cf-admin-password --from-literal=password=$CLUSTER_PASSWORD || true

    # Install the operator
    helm install --namespace scf \
    --name cf-operator \
    --set "provider=gke" --set "customResources.enableInstallation=true" \
    "$OPERATOR_CHART_URL" || true

    bash "$ROOT_DIR"/include/wait_ns.sh scf
    sleep 10

    helm install --name susecf-scf ${SCF_CHART} \
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

ok "SCF deployed successfully"
