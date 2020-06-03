#!/usr/bin/env bash

# Requires:
# - az credentials present

. ./defaults.sh
. ../../include/common.sh
. .envrc

if ! az account show; then
    info "Missing azure credentials, running az login…"
    # https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest#sign-in-using-a-service-principal
    az login --service-principal \
       --username "${AZURE_APP_ID}" \
       --password "${AZURE_PASSWORD}" \
       --tenant "${AZURE_TENANT_ID}"
fi

# Check that KUBECTL_VERSION specified is available in azure location
available_kube_versions=$(az aks get-versions -l "${AZURE_LOCATION}" | jq -c '[.orchestrators[] | select(.orchestratorType == "Kubernetes") | .orchestratorVersion]')
if [[ -z $(jq 'index("'${KUBECTL_VERSION#v}'") // empty' <<< $available_kube_versions) ]]; then
    err "kubectl version ${KUBECTL_VERSION#v} not available in aks location ${AZURE_LOCATION}"
    info "Check KUBECTL_VERSION and AZURE_LOCATION settings"
    info "Available versions in ${AZURE_LOCATION}: $available_kube_versions"
    exit 1
fi

git clone https://github.com/SUSE/cap-terraform.git -b cap-ci
pushd cap-terraform/aks || exit

# terraform needs helm client installed and configured:
helm_init_client

# ssh_public_key needs to be a file. Build it regardless of {ssh,gpg}-agent, or
# forwarding of agents:
ssh-add -L
(ssh-add -L | head -n 1) > ./sshkey.pub

cat <<HEREDOC > terraform.tfvars
cluster_name      = "${AZURE_CLUSTER_NAME}"
az_resource_group = "${AZURE_RESOURCE_GROUP}"
client_id         = "${AZURE_APP_ID}"
client_secret     = "${AZURE_PASSWORD}"
ssh_public_key    = "./sshkey.pub"
instance_count    = "${AZURE_NODE_COUNT}"
location          = "${AZURE_LOCATION}"
agent_admin       = "cap-admin"
cluster_labels    = {
    "catapult-cluster" = "${AZURE_CLUSTER_NAME}",
    "owner"            = "$(whoami)"
}
k8s_version       = "${KUBECTL_VERSION}"
azure_dns_json    = "${AZURE_DNS_JSON}"
dns_zone_rg       = "${AZURE_DNS_RESOURCE_GROUP}"
HEREDOC

if [ -n "${TF_KEY}" ] ; then
    cat > backend.tf <<EOF
terraform {
  backend "s3" {
      bucket = "${TF_BUCKET}"
      region = "${TF_REGION}"
      key    = "${TF_KEY}"
  }
}
EOF
fi

terraform init

terraform plan -out=my-plan

if [ -n "${TF_KEY}" ] ; then
    # zip the terraform folder to use in concourse pool
    zip -r9  "${BUILD_DIR}/tf-setup.zip" .
fi

# temporarily change KUBECONFIG, needed for terraform scripts:
KUBECONFIG="$(pwd)"/aksk8scfg

terraform apply -auto-approve my-plan

# restore correct KUBECONFIG:
KUBECONFIG="${BUILD_DIR}"/kubeconfig

# get kubectl for aks:
cp aksk8scfg "${KUBECONFIG}"

# wait for cluster ready:
wait_ns kube-system

# test deployment:
kubectl get svc

ROOTFS=overlay-xfs
# take first worker node as public ip:
wait_for 'PUBLIC_IP="$(kubectl get services nginx-ingress-nginx-ingress-controller -o json | jq -r '.status[].ingress[].ip' 2>/dev/null)"'
DOMAIN="$AZURE_CLUSTER_NAME.$MAGICDNS"
if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=garden-rootfs-driver="${ROOTFS}" \
            --from-literal=public-ip="${PUBLIC_IP}" \
            --from-literal=domain="${DOMAIN}" \
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
