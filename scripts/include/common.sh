#!/bin/bash

export VALUES_OVERRIDE="${VALUES_OVERRIDE:-}"
OVERRIDE=
if [ -n "$VALUES_OVERRIDE" ] && [ -f "$VALUES_OVERRIDE" ]; then
  OVERRIDE=$(cat $VALUES_OVERRIDE)
fi

export CLUSTER_NAME=${CLUSTER_NAME:-kind}
export BUILD_DIR=build${CLUSTER_NAME}

# Forces our build context
[ -d "$BUILD_DIR" ] && pushd "$BUILD_DIR"

export ROOT_DIR="$(git rev-parse --show-toplevel)"
export CHART_URL="${CHART_URL:-}"
export KUBECONFIG=$PWD/kubeconfig
export SCF_REPO="${SCF_REPO:-https://github.com/SUSE/scf}"
export SCF_BRANCH="${SCF_BRANCH:-develop}"
if [ -n "$EKCP_HOST" ]; then
  export container_ip=$(curl -s http://$EKCP_HOST/ | jq .ClusterIPs.${CLUSTER_NAME} -r)
  export DOMAIN="${CLUSTER_NAME}.${container_ip}.${EKCP_DOMAIN}"
else
  export container_id=$(docker ps -f "name=${cluster_name}-control-plane" -q)
  export container_ip=$(docker inspect $container_id | jq -r .[0].NetworkSettings.Networks.bridge.IPAddress)
  export DOMAIN="${container_ip}.nip.io"
fi

export DEEP_CLEAN="${DEEP_CLEAN:-false}" # If true, triggers helm to delete releases before cleaning up
export KIND_VERSION="${KIND_VERSION:-0.2.1}"
export HA="${HA:-false}"
export SIZING="${SIZING:-1}"
export DOCKER_REGISTRY="${DOCKER_REGISTRY:-registry.suse.com}"
export DOCKER_ORG="${DOCKER_ORG:-cap}"
set +x
export DOCKER_USERNAME="${DOCKER_USERNAME:-}"
export DOCKER_PASSWORD="${DOCKER_PASSWORD:-}"
export CLUSTER_PASSWORD="${CLUSTER_PASSWORD:-password}"
set -x
export ENABLE_EIRINI="${ENABLE_EIRINI:-true}"
export EMBEDDED_UAA="${EMBEDDED_UAA:-false}"
export KIND_APIVERSION="${KIND_APIVERSION:-kind.sigs.k8s.io/v1alpha2}"
if [ -z "${DEFAULT_STACK}" ]; then
  export DEFAULT_STACK=$(helm inspect helm/cf/ | grep DEFAULT_STACK | sed  's~DEFAULT_STACK:~~g' | sed 's~"~~g' | sed 's~\s~~g')
fi
