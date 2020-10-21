#!/usr/bin/env bash


# Takes a newly deployed Caasp4 cluster, provided by the kubeconfig, and prepares
# it for CAP
#
# Requires:
# kubectl & helm binaries

. ./defaults.sh
. ../../include/common.sh
. .envrc

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

install_helm_and_tiller() {
  if [[ "$HELM_VERSION" != v3* ]]; then
    if kubectl get pods --all-namespaces 2>/dev/null | grep -qi tiller; then
        # Tiller already present
        helm init --client-only
    else
        kubectl create serviceaccount tiller --namespace kube-system
        helm init --wait
    fi
  else
    helm_init
  fi
}

create_cpi_storageclass() {
    if ! kubectl get storageclass 2>/dev/null | grep -qi persistent; then
        kubectl apply -f - <<HEREDOC
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: persistent
provisioner: kubernetes.io/cinder
HEREDOC
    fi
    kubectl patch storageclass persistent \
            -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
}


# create_rolebinding
install_helm_and_tiller
create_cpi_storageclass

ok "CaaSP4 on Openstack succesfully prepared!"
