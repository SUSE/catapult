#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ./defaults.sh
. ../../include/common.sh
. .envrc

# check gcloud credentials:
if [[ $(gcloud auth list  --format="value(account)" | wc -l ) -le 0 ]]; then
    echo ">>> Missing gcloud credentials, aborting" && exit 1
fi
# one needs the following roles. We cannot check programmatically as
# you normally don't have permission to list roles:
# gcloud projects add-iam-policy-binding <project> \
#        --member=user:<user> \
#        --role=roles/container.admin

git clone https://github.com/SUSE/cap-terraform.git
pushd cap-terraform/gke || exit

cat <<HEREDOC > terraform.tfvars
project = "$GKE_PROJECT"
location = "$GKE_LOCATION"
node_pool_name = "$GKE_CLUSTER_NAME"
vm_type = "UBUNTU"
gke_sa_key = "$GKE_CRED_JSON"
gcp_dns_sa_key = "$GKE_CRED_JSON"
cluster_labels = {key = "$GKE_CLUSTER_NAME"}
k8s_version = "latest"
HEREDOC

# terraform needs helm client installed and configured:
helm init --client-only

info "Deploying GKE cluster with terraform…"

terraform init

terraform plan -out="$(pwd)"/my-plan

terraform apply -auto-approve
popd || exit

# wait for cluster ready:
wait_ns kube-system

info "Configuring deployed GKE cluster…"

ROOTFS=overlay-xfs
# take first worker node as public ip:
PUBLIC_IP="$(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address' | head -n 1)"
DOMAIN="$PUBLIC_IP.$MAGICDNS"
if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=garden-rootfs-driver="${ROOTFS}" \
            --from-literal=public-ip="${PUBLIC_IP}" \
            --from-literal=domain="${DOMAIN}" \
            --from-literal=platform=gke
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

ok "GKE cluster deployed"
