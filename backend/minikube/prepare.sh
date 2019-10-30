#!/bin/bash
set -x

. ../../include/common.sh
. .envrc

kubectl create clusterrolebinding admin --clusterrole=cluster-admin --user=system:serviceaccount:kube-system:default
kubectl create clusterrolebinding uaaadmin --clusterrole=cluster-admin --user=system:serviceaccount:uaa:default
kubectl create clusterrolebinding scfadmin --clusterrole=cluster-admin --user=system:serviceaccount:scf:default

cat > storageclass.yaml <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: persistent
  resourceVersion: "352"
  selfLink: /apis/storage.k8s.io/v1/storageclasses/standard
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

kubectl create -f ./storageclass.yaml
kubectl delete storageclass standard
helm init --upgrade --wait

container_ip=$(minikube ip)
domain="${container_ip}.$MAGICDNS"

if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=public-ip="${container_ip}" \
            --from-literal=domain="$domain" \
            --from-literal=platform="minikube"
fi
