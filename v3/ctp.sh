#!/usr/bin/env bash

# trap if failure, return 255 to signal CI failure, not test failure

# validate catapult-values with schema

debug_mode

# obtain tools



# source all helper scripts, binaries, etc.
# Transition scripts are not allowed to source anything themselves,
# to make sure they operate inside the harness, and don't hardcode
# dependencies on each other

export DEBUG_MODE="${DEBUG_MODE:-false}"
source "$ROOT_DIR"/include/func.sh
source "$ROOT_DIR"/include/colors.sh

if [ -n "$CONFIG" ]; then
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
# from now on, transition scripts operate inside the harness
# they are not allowed to source anything on their own
[ -d "$BUILD_DIR" ] && pushd "$BUILD_DIR" || true

. "$ROOT_DIR"/include/defaults_global.sh
set +x
. "$ROOT_DIR"/include/defaults_global_private.sh
debug_mode

info "Loading"


set -Eeuo pipefail

. .envrc
# we are now in the harness



# run every executable in the folder, starting with numbers
