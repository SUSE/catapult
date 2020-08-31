#!/bin/bash

export DEBUG_MODE="${DEBUG_MODE:-false}"
source "$ROOT_DIR"/include/func.sh
source "$ROOT_DIR"/include/colors.sh

debug_mode

if [ -n "${CONFIG:-}" ]; then
  load_env_from_json "$CONFIG"
fi

export VALUES_OVERRIDE="${VALUES_OVERRIDE:-}"
OVERRIDE=
if [ -n "$VALUES_OVERRIDE" ] && [ -f "$VALUES_OVERRIDE" ]; then
  OVERRIDE=$(cat "$VALUES_OVERRIDE")
  export OVERRIDE
fi

export BACKEND="${BACKEND:-kind}"
export CLUSTER_NAME=${CLUSTER_NAME:-$BACKEND}
#export ROOT_DIR="$(git rev-parse --show-toplevel)"
export BUILD_DIR="$ROOT_DIR"/build${CLUSTER_NAME}

# Forces our build context
[ -d "$BUILD_DIR" ] && pushd "$BUILD_DIR" || true

. "$ROOT_DIR"/include/defaults_global.sh
set +x
. "$ROOT_DIR"/include/defaults_global_private.sh
debug_mode

info "Loading"

# set as much restrictive bash options as possible for following scripts.
# If needed, relax options in the specific script.
set -Eeuo pipefail
