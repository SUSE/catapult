#!/usr/bin/env bash

. ./defaults.sh

set -Eeuo pipefail

if [[ "$(docker images -q skuba/$CAASP_VER 2> /dev/null)" == "" ]]; then
    info "Creating skuba/$CAASP_VER container image…"
		make -C docker/skuba/ "$CAASP_VER"
    ok "skuba/$CAASP_VER container image created!"
fi
