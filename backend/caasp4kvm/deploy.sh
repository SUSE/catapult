#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ../../include/common.sh
. .envrc

set -Eexuo pipefail

git clone https://github.com/SUSE/cap-terraform.git
pushd cap-terraform
git checkout terrafrom-kvm #sic
pushd caasp4-kvm
read


# Substitute:
# "libvirt_uri": "qemu:///system",

# GKE_PROJECT="${GKE_PROJECT:-suse-css-platform}"
# GKE_LOCATION="${GKE_LOCATION:-europe-west4-a}"
# GKE_CLUSTER_NAME="${GKE_CLUSTER_NAME:-$(whoami)-cap}"
# GKE_CRED_JSON="${GKE_CRED_JSON:-}"

# cat <<HEREDOC > terraform.tfvars
# project = "$GKE_PROJECT"
# location = "$GKE_LOCATION"
# node_pool_name = "$GKE_CLUSTER_NAME"
# vm_type = "UBUNTU"
# gke_sa_key = "$GKE_CRED_JSON"
# gcp_dns_sa_key = "$GKE_CRED_JSON"
# cluster_labels = {key = "$GKE_CLUSTER_NAME"}
# k8s_version = "latest"
# HEREDOC

# terraform needs helm client installed and configured:
helm init --client-only

terraform init

terraform plan -out="$(pwd)"/my-plan

terraform apply -auto-approve
popd

# wait for cluster ready:
bash "$ROOT_DIR"/include/wait_ns.sh kube-system

ROOTFS=overlay-xfs
# take first worker node as public ip:
PUBLIC_IP="$(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address' | head -n 1)"
DOMAIN="$PUBLIC_IP.$MAGICDNS"
if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=garden-rootfs-driver="${ROOTFS}" \
            --from-literal=public-ip="${PUBLIC_IP}" \
            --from-literal=domain="${DOMAIN}" \
            --from-literal=platform=caasp4kvm
fi

# create_rolebinding() {

#     kubectl create clusterrolebinding admin --clusterrole=cluster-admin --user=system:serviceaccount:kube-system:default
#     kubectl create clusterrolebinding uaaadmin --clusterrole=cluster-admin --user=system:serviceaccount:uaa:default
#     kubectl create clusterrolebinding scfadmin --clusterrole=cluster-admin --user=system:serviceaccount:scf:default

#     kubectl apply -f - <<HEREDOC
# ---
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRole
# metadata:
#   annotations:
#     rbac.authorization.kubernetes.io/autoupdate: "true"
#   labels:
#     kubernetes.io/bootstrapping: rbac-defaults
#   name: cluster-admin
# rules:
# - apiGroups:
#   - '*'
#   resources:
#   - '*'
#   verbs:
#   - '*'
# - nonResourceURLs:
#   - '*'
#   verbs:
#   - '*'
# ---
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   name: kube-system:default
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: cluster-admin
# subjects:
# - kind: ServiceAccount
#   name: default
#   namespace: kube-system
# HEREDOC
# }
# create_rolebinding
