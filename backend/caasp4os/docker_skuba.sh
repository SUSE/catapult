#!/usr/bin/env bash

. ./defaults.sh

set -Eeuo pipefail

if [[ "$(docker images -q skuba/$CAASP_VER 2> /dev/null)" == "" ]]; then
		make -C docker/skuba/ "$CAASP_VER"
fi
