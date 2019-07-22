#!/bin/bash

# Forces our build context
[ -d "build" ] && pushd build

export CHART_URL="${CHART_URL:-}"
export KUBECONFIG=kubeconfig
export SCF_REPO="${SCF_REPO:-https://github.com/SUSE/scf}"
export SCF_BRANCH="${SCF_BRANCH:-develop}"
export cluster_name=$(./kind get clusters)
export container_id=$(docker ps -f "name=${cluster_name}-control-plane" -q)
export container_ip=$(docker inspect $container_id | jq -r .[0].NetworkSettings.Networks.bridge.IPAddress)

export DEEP_CLEAN="${DEEP_CLEAN:-false}" # If true, triggers helm to delete releases before cleaning up
 

export DOCKER_REGISTRY="${DOCKER_REGISTRY:-registry.suse.com}"
export DOCKER_ORG="${DOCKER_ORG:-cap}"
export DOCKER_USERNAME="${DOCKER_USERNAME:-}"
export DOCKER_PASSWORD="${DOCKER_PASSWORD:-}"
export ENABLE_EIRINI="${ENABLE_EIRINI:-true}"
export CREATE_EIRINI_NAMESPACE="${CREATE_EIRINI_NAMESPACE:-false}"


if [ -z "${DEFAULT_STACK}" ]; then
  export DEFAULT_STACK=$(helm inspect helm/cf/ | grep DEFAULT_STACK | sed  's~DEFAULT_STACK:~~g' | sed 's~"~~g' | sed 's~\s~~g')
fi