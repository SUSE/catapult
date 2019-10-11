#!/bin/bash
set -x

. ../include/common.sh
. .envrc

kubectl create clusterrolebinding admin --clusterrole=cluster-admin --user=system:serviceaccount:kube-system:default
kubectl create clusterrolebinding uaaadmin --clusterrole=cluster-admin --user=system:serviceaccount:uaa:default
kubectl create clusterrolebinding scfadmin --clusterrole=cluster-admin --user=system:serviceaccount:scf:default

cat > storageclass.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: hostpath-provisioner
  namespace: kube-system
---

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: hostpath-provisioner
  namespace: kube-system
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["list", "watch", "create", "update", "patch"]
---

apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: docker.io/hostpath
reclaimPolicy: Retain
EOF

kubectl delete storageclass standard
kubectl create -f ../kube/storageclass.yaml
helm init --upgrade --wait

container_ip=$(minikube ip)
domain="${container_ip}.omg.howdoi.website"

if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=public-ip="${container_ip}" \
            --from-literal=domain="$domain" \
            --from-literal=platform="minikube"
fi
