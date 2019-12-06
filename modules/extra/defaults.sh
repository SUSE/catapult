#!/usr/bin/env bash

# Extra module options
######################

KWT_VERSION="${KWT_VERSION:-v0.0.5}"
KWT_OS_TYPE="${KWT_OS_TYPE:-linux-amd64}"

TMPDIR="${TMPDIR:-/tmp}" # required to be able to mount configs in deployments containers (dind mount )
