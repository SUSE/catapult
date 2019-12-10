#!/usr/bin/env bash

set -Eeuo pipefail

. ./defaults.sh

if [[ "$(docker images -q skuba/$CAASP_VER 2> /dev/null)" == "" ]]; then
		make -C docker/skuba/ "$CAASP_VER"
fi
