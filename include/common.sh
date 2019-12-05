#!/bin/bash

export DEBUG_MODE="${DEBUG_MODE:-false}"
source "$ROOT_DIR"/include/func.sh

debug_mode

if [ -n "$CONFIG" ]; then
  load_env_from_json "$CONFIG"
fi

export BACKEND="${BACKEND:-kind}"
export VALUES_OVERRIDE="${VALUES_OVERRIDE:-}"
OVERRIDE=
if [ -n "$VALUES_OVERRIDE" ] && [ -f "$VALUES_OVERRIDE" ]; then
  OVERRIDE=$(cat "$VALUES_OVERRIDE")
fi

export CLUSTER_NAME=${CLUSTER_NAME:-$BACKEND}
#export ROOT_DIR="$(git rev-parse --show-toplevel)"
export BUILD_DIR="$ROOT_DIR"/build${CLUSTER_NAME}

# Forces our build context
[ -d "$BUILD_DIR" ] && pushd "$BUILD_DIR"

export SCF_REPO="${SCF_REPO:-https://github.com/SUSE/scf}"
export SCF_BRANCH="${SCF_BRANCH:-develop}"
export DOCKER_REGISTRY="${DOCKER_REGISTRY:-registry.suse.com}"
export DOCKER_ORG="${DOCKER_ORG:-cap}"
set +x
export DOCKER_USERNAME="${DOCKER_USERNAME:-}"
export DOCKER_PASSWORD="${DOCKER_PASSWORD:-}"
debug_mode

export MAGICDNS="${MAGICDNS:-nip.io}"
export ENABLE_EIRINI="${ENABLE_EIRINI:-true}"
export KUBEPROXY_PORT="${KUBEPROXY_PORT:-2224}"
export QUIET_OUTPUT="${QUIET_OUTPUT:-false}"


info "Loading"

# set as much restrictive bash options as possible for following scripts.
# If needed, relax options in the specific script.
set -Eeuo pipefail
