#!/usr/bin/env bash

. ../../include/common.sh
pushd  "$ROOT_DIR"/backend/caasp4os || exit
. defaults.sh

set -Eeuo pipefail

if [[ "$(docker images -q skuba/$CAASP_VER 2> /dev/null)" == "" ]]; then
    info "Creating skuba/$CAASP_VER container image…"
		make -C docker/skuba/ "$CAASP_VER"
    ok "skuba/$CAASP_VER container image created!"
fi
