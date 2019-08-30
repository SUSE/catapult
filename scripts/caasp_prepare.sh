#!/usr/bin/env bash


# Takes a newly deployed Caasp4 cluster, provided by the kubeconfig, and prepares
# it for CAP
#
# Requires:
# kubectl & helm binaries

. scripts/include/caasp4os.sh
. scripts/include/common.sh

set -exuo pipefail
. .envrc

create_rolebinding() {
    kubectl apply -f - << HEREDOC
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

install_helm_and_tiller() {
    if kubectl get pods --all-namespaces 2>/dev/null | grep -qi tiller; then
        # Tiller already present
        helm init --client-only
    else
        kubectl create serviceaccount tiller --namespace kube-system
        helm init --wait
    fi
}

create_nfs_storageclass() {
    # Create nfs storageclass with provided nfs server
    if ! kubectl get storageclass 2>/dev/null | grep -qi persistent; then
        NFS_SERVER_IP=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["nfs-server-ip"]')
        NFS_PATH=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["nfs-path"]')
        helm install stable/nfs-client-provisioner \
             --set nfs.server="$NFS_SERVER_IP" \
             --set nfs.path="$NFS_PATH" \
             --set storageClass.name=persistent \
             --set storageClass.reclaimPolicy=Delete \
             --set storageClass.archiveOnDelete=false
    fi
}

create_rolebinding
install_helm_and_tiller
create_nfs_storageclass
