#!/usr/bin/env bash

# Global options
################

export SCF_REPO="${SCF_REPO:-https://github.com/SUSE/scf}"
export SCF_BRANCH="${SCF_BRANCH:-develop}"
export DOCKER_REGISTRY="${DOCKER_REGISTRY:-registry.suse.com}"
export DOCKER_ORG="${DOCKER_ORG:-cap}"

export DEFAULT_STACK="${DEFAULT_STACK:-from_chart}" # from_chart, sle15, sle12, cfslinuxfs2, cfslinuxfs3
export MAGICDNS="${MAGICDNS:-nip.io}"
export ENABLE_EIRINI="${ENABLE_EIRINI:-true}"
export EKCP_PROXY="${EKCP_PROXY:-}"
export KUBEPROXY_PORT="${KUBEPROXY_PORT:-2224}"
export QUIET_OUTPUT="${QUIET_OUTPUT:-false}"

# Download binaries of helm, kubectl, cf, etc
DOWNLOAD_BINS="${DOWNLOAD_BINS:-true}"

# Download binaries of catapult dependencies
DOWNLOAD_CATAPULT_DEPS="${DOWNLOAD_CATAPULT_DEPS:-true}"
