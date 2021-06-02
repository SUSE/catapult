#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [[ $ENABLE_EIRINI == true ]] ; then
   # [ ! -f "helm/cf/templates/eirini-namespace.yaml" ] && kubectl create namespace eirini
    if ! kubectl get clusterrole system:metrics-server &> /dev/null; then
        helm_install metrics-server stable/metrics-server\
             --set args[0]="--kubelet-preferred-address-types=InternalIP" \
             --set args[1]="--kubelet-insecure-tls" || true

        echo "Waiting for metrics server to come up..."
        wait_ns default
        sleep 10
    fi
fi

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

# Detect the chart version to handle different install parameters
operator_version="$(helm_chart_app_version "${OPERATOR_CHART_URL}")"
operator_install_args=(
    --set "operator-webhook-use-service-reference=true"
    --set "customResources.enableInstallation=true"
)
info "operator_version: ${operator_version}"
if [[ "${operator_version%%.*}" -ge 5 ]]; then
    info "operator_version is greater than 5"
    info "setting param global.singleNamespace.name"
    operator_install_args+=(--set "global.singleNamespace.name=scf")
else
    # quarks-operator 4.x uses a different key to target namespace to watch
    info "operator_version is less than 5"
    info "setting param global.operator.watchNamespace"
    operator_install_args+=(--set "global.operator.watchNamespace=scf")
fi

if [[ "${DOCKER_REGISTRY}" != "registry.suse.com" ]]; then
  operator_install_args+=(--set "image.org=${DOCKER_REGISTRY}/${DOCKER_ORG}")
  operator_install_args+=(--set "quarks-job.image.org=${DOCKER_REGISTRY}/${DOCKER_ORG}")
  operator_install_args+=(--set "operator.boshDNSDockerImage=${DOCKER_REGISTRY}/${DOCKER_ORG}/coredns:0.1.0-1.6.7-bp152.1.2")
  operator_install_args+=(--set "createWatchNamespace=false")
  operator_install_args+=(--set "quarks-job.createWatchNamespace=false")
  operator_install_args+=(--set "global.singleNamespace.create=false")
  operator_install_args+=(--set "quarks-job.singleNamespace.createNamespace=false")
  operator_install_args+=(--set "quarks-job.global.singleNamespace.create=false")
fi


echo "Installing CFO from: ${OPERATOR_CHART_URL}"

kubectl create namespace cf-operator || true
# Install the operator

helm_install cf-operator "${OPERATOR_CHART_URL}" --namespace cf-operator \
    "${operator_install_args[@]}"

info "Wait for cf-operator to be ready"

wait_for_cf-operator

ok "cf-operator ready"

helm_install susecf-scf ${SCF_CHART} \
  --namespace scf \
  --values scf-config-values.yaml

sleep 540

wait_for_kubecf

ok "KubeCF deployed successfully"
