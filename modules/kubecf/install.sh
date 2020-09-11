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
if [[ "${operator_version%%.*}" -ge 5 ]]; then
    operator_install_args+=(--set "global.singleNamespace.name=scf")
else
    # quarks-operator 4.x uses a different key to target namespace to watch
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
# fixes operator readiness issue on AKS.
sleep 240

wait_ns cf-operator

info "Wait for cf-operator to be ready"
wait_for "kubectl get endpoints -n cf-operator cf-operator-webhook -o name"
wait_for "kubectl get crd quarksstatefulsets.quarks.cloudfoundry.org -o name"
wait_for "kubectl get crd quarkssecrets.quarks.cloudfoundry.org -o name"
wait_for "kubectl get crd quarksjobs.quarks.cloudfoundry.org -o name"
wait_for "kubectl get crd boshdeployments.quarks.cloudfoundry.org -o name"
info "Test CRDs are ready"
#wait_for "kubectl apply -f ../kube/cf-operator/boshdeployment.yaml --namespace=scf"
wait_for "kubectl apply -f ../kube/cf-operator/password.yaml --namespace=scf"
if [[ "${DOCKER_REGISTRY}" == "registry.suse.com" ]]; then
  # qstate_tolerations fails when internet connectivity is disabled.
  wait_for "kubectl apply -f ../kube/cf-operator/qstatefulset_tolerations.yaml --namespace=scf"
fi
wait_ns scf
#wait_for "kubectl delete -f ../kube/cf-operator/boshdeployment.yaml --namespace=scf"
wait_for "kubectl delete -f ../kube/cf-operator/password.yaml --namespace=scf"
if [[ "${DOCKER_REGISTRY}" == "registry.suse.com" ]]; then
  wait_for "kubectl delete -f ../kube/cf-operator/qstatefulset_tolerations.yaml --namespace=scf"
fi
ok "cf-operator ready"

# KubeCF Doesn't support to setup a cluster password yet, doing it manually.

## Versions of cf-operator prior to 4 included deployment name in front of secrets
## Note: this can be dropped once we don't test anymore kubecf 1.x. in favor of the secret without the
## deployment name, or either we can clearly identify the operator version without hackish ways.
kubectl create secret generic -n scf susecf-scf.var-cf-admin-password --from-literal=password="${CLUSTER_PASSWORD}"

## CF-Operator >= 4 don't have deployment name in front of secrets name anymore
kubectl create secret generic -n scf var-cf-admin-password --from-literal=password="${CLUSTER_PASSWORD}"

helm_install susecf-scf ${SCF_CHART} \
  --namespace scf \
  --values scf-config-values.yaml

sleep 540

wait_ns scf
if [ "$services" == "lb" ]; then
    external_dns_annotate_kubecf scf "$domain"
fi

ok "KubeCF deployed successfully"
