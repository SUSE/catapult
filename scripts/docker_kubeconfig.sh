#!/bin/bash
set -ex
. scripts/include/common.sh

# Tweaks the kubeconfig so it can be called from the docker container network (in case the cluster is created with dind)
sed -i "s/localhost.*/${container_ip}:6443/" kubeconfig