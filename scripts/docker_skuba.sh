#!/usr/bin/env bash

set -xeuo pipefail

. scripts/include/caasp4os.sh

if [[ "$(docker images -q skuba/$CAASP_VER 2> /dev/null)" == "" ]]; then
		make -C caasp4/docker/skuba/ "$CAASP_VER"
fi
