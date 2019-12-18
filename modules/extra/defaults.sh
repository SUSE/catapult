#!/usr/bin/env bash

# Extra module options
######################

## Stern
STERN_ARGS="${STERN_ARGS:---all-namespaces .}"
STERN_VERSION="${STERN_VERSION:-1.11.0}"
STERN_OS_TYPE="${STERN_OS_TYPE:-linux_amd64}"

## Kwt
KWT_VERSION="${KWT_VERSION:-v0.0.5}"
KWT_OS_TYPE="${KWT_OS_TYPE:-linux-amd64}"

## Catapult-web
# required to be able to mount configs in deployments containers (dind mount for deployments from web interface)
TMPDIR="${TMPDIR:-/tmp}"

## Fissile
FISSILE_OPT_BOSH_RELEASE="${FISSILE_OPT_BOSH_RELEASE:-}"
FISSILE_OPT_STEMCELL="${FISSILE_OPT_STEMCELL:-splatform/fissile-stemcell-sle:SLE_15_SP1-15.1}"
FISSILE_OPT_RELEASE_NAME="${FISSILE_OPT_RELEASE_NAME:-fissile-release}"
FISSILE_OPT_RELEASE_VERSION="${FISSILE_OPT_RELEASE_VERSION:-0.1}"

## K9s
K9S_VERSION="${K9S_VERSION:-0.9.3}"
K9S_OS_TYPE="${K9S_OS_TYPE:-Linux_x86_64}"
