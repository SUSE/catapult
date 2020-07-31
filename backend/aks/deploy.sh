#!/usr/bin/env bash

# Requires:
# - az credentials present

. ./defaults.sh
. ../../include/common.sh
. .envrc

if ! az account show; then
    info "Missing azure credentials, running az login into the account."
    # https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest#sign-in-using-a-service-principal
    az login --service-principal \
       --username "${AZURE_APP_ID}" \
       --password "${AZURE_PASSWORD}" \
       --tenant "${AZURE_TENANT_ID}"

    az account set --subscription="${AZURE_SUBSCRIPTION_ID}"
fi

# Check that KUBECTL_VERSION specified is available in azure location
available_kube_versions=$(az aks get-versions --output json -l "${AZURE_LOCATION}" | jq -c '[.orchestrators[] | select(.orchestratorType == "Kubernetes") | .orchestratorVersion]')
if [[ -z $(jq 'index("'${KUBECTL_VERSION#v}'") // empty' <<< $available_kube_versions) ]]; then
    err "kubectl version ${KUBECTL_VERSION#v} not available in aks location ${AZURE_LOCATION}"
    info "Check KUBECTL_VERSION and AZURE_LOCATION settings"
    info "Available versions in ${AZURE_LOCATION}: $available_kube_versions"
    exit 1
fi

# Required env vars for deploying via Azure SP.
# see: https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html#configuring-the-service-principal-in-terraform
export ARM_CLIENT_ID="${AZURE_APP_ID}"
export ARM_CLIENT_SECRET="${AZURE_PASSWORD}"
export ARM_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
export ARM_TENANT_ID="${AZURE_TENANT_ID}"

pushd cap-terraform/aks || exit
# ssh_public_key needs to be a file. Build it regardless of {ssh,gpg}-agent, or
# forwarding of agents:
ssh-add -L
(ssh-add -L | head -n 1) > ./sshkey.pub

terraform init

terraform plan -out=my-plan

# temporarily change KUBECONFIG, needed for terraform scripts:
KUBECONFIG="$(pwd)"/aksk8scfg

terraform apply -auto-approve my-plan

# restore correct KUBECONFIG:
KUBECONFIG="${BUILD_DIR}"/kubeconfig

# get kubectl for aks:
cp aksk8scfg "${KUBECONFIG}"
popd

# wait for cluster ready:
wait_ns kube-system

# test deployment:
kubectl get svc

ROOTFS=overlay-xfs
# take first worker node as public ip:
wait_for 'PUBLIC_IP="$(kubectl get services nginx-ingress-nginx-ingress-controller -o json | jq -r '.status[].ingress[].ip' 2>/dev/null)"'
if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=garden-rootfs-driver="${ROOTFS}" \
            --from-literal=public-ip="${PUBLIC_IP}" \
            --from-literal=domain="${AZURE_DNS_DOMAIN}" \
            --from-literal=platform=aks
fi

create_rolebinding() {

    kubectl create clusterrolebinding admin --clusterrole=cluster-admin --user=system:serviceaccount:kube-system:default
    kubectl create clusterrolebinding uaaadmin --clusterrole=cluster-admin --user=system:serviceaccount:uaa:default
    kubectl create clusterrolebinding scfadmin --clusterrole=cluster-admin --user=system:serviceaccount:scf:default

    kubectl apply -f - <<HEREDOC
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: cluster-admin
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-system:default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: kube-system
HEREDOC
}
create_rolebinding
