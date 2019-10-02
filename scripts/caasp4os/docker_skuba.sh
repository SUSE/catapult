#!/usr/bin/env bash

set -xeuo pipefail

. "$( dirname "${BASH_SOURCE[0]}" )"/caasp4os.sh

if [[ "$(docker images -q skuba/$CAASP_VER 2> /dev/null)" == "" ]]; then
		make -C docker/skuba/ "$CAASP_VER"
fi
