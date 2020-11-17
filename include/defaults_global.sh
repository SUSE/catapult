#!/usr/bin/env bash

# Global options
################

export DOCKER_REGISTRY="${DOCKER_REGISTRY:-registry.suse.com}"
export DOCKER_ORG="${DOCKER_ORG:-cap}"

export DEFAULT_STACK="${DEFAULT_STACK:-from_chart}" # from_chart, sle15, sle12, cfslinuxfs2, cfslinuxfs3
export MAGICDNS="${MAGICDNS:-omg.howdoi.website}"
export ENABLE_EIRINI="${ENABLE_EIRINI:-false}"
export EKCP_PROXY="${EKCP_PROXY:-}"
export KUBEPROXY_PORT="${KUBEPROXY_PORT:-2224}"
export QUIET_OUTPUT="${QUIET_OUTPUT:-false}"

# Download binaries of helm, kubectl, cf, etc
export DOWNLOAD_BINS="${DOWNLOAD_BINS:-true}"

# Download binaries of catapult dependencies
export DOWNLOAD_CATAPULT_DEPS="${DOWNLOAD_CATAPULT_DEPS:-true}"
export CAP_TERRAFORM_REPOSITORY="${CAP_TERRAFORM_REPOSITORY:-https://github.com/SUSE/cap-terraform.git}"
export CAP_TERRAFORM_BRANCH="${CAP_TERRAFORM_BRANCH:-cap-ci}"
