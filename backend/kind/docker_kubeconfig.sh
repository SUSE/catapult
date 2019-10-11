#!/bin/bash
set -ex

. ../../include/common.sh
. .envrc

export container_id=$(docker ps -f "name=${CLUSTER_NAME}-control-plane" -q)
export container_ip=$(docker inspect $container_id | jq -r .[0].NetworkSettings.Networks.bridge.IPAddress)

# Tweaks the kubeconfig so it can be called from the docker container network (in case the cluster is created with dind)
sed -i "s/localhost.*/${container_ip}:6443/" kubeconfig
