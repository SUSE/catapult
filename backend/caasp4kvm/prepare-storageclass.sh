#!/bin/bash

cluster=$(pwd | sed -e 's|/.*./||g' -e 's|-cluster||g')
tiller=$(kubectl get pods -n kube-system | grep tiller-deploy | awk '{print$1}')

if [ -z "$tiller" ]; then
   kubectl create serviceaccount tiller --namespace kube-system
   kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
   helm init --upgrade --service-account tiller
   tiller=$(kubectl get pods -n kube-system | grep tiller-deploy | awk '{print$1}')
   while [[ $node_readiness != "True" ]]; do
         node_readiness=$(kubectl get pod $tiller -n kube-system -o json | jq -r '.status.conditions[] | select(.type == "Ready").status')
   done
fi

helm install stable/nfs-client-provisioner --name nfs-client-provisioner --namespace kube-system --values nfs-client-values_$cluster.yaml
