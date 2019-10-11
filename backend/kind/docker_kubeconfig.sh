#!/bin/bash
set -ex

. ../../include/common.sh

public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')

# Tweaks the kubeconfig so it can be called from the docker container network (in case the cluster is created with dind)
sed -i "s/localhost.*/${public_ip}:6443/" kubeconfig