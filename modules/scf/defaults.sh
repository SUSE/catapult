#!/bin/bash

# SCF options
#############

# scf-chart revelant:

export CHART_URL="${CHART_URL:-}" # FIXME deprecated, used in SCF_CHART
export SCF_CHART="${SCF_CHART:-$CHART_URL}"

export SCF_HELM_VERSION="${SCF_HELM_VERSION:-}"
export OPERATOR_CHART_URL="${OPERATOR_CHART_URL:-latest}"

# scf-gen-config relevant:

export SCF_SERVICES="${SCF_SERVICES:-lb}" # lb, ingress
export GARDEN_ROOTFS_DRIVER="${GARDEN_ROOTFS_DRIVER:-overlay-xfs}"
export DIEGO_SIZING="${DIEGO_SIZING:-$SIZING}"
export STORAGECLASS="${STORAGECLASS:-persistent}"
export AUTOSCALER="${AUTOSCALER:-false}"

export EMBEDDED_UAA="${EMBEDDED_UAA:-false}"

export HA="${HA:-false}"
if [ "$HA" = "true" ]; then
    export SIZING="${SIZING:-2}"
else
    export SIZING="${SIZING:-1}"
fi

export UAA_UPGRADE="${UAA_UPGRADE:-true}"

OVERRIDE="${OVERRIDE:-}"
export CONFIG_OVERRIDE="${CONFIG_OVERRIDE:-$OVERRIDE}"

export BRAIN_VERBOSE="${BRAIN_VERBOSE:-false}"
export BRAIN_INORDER="${BRAIN_INORDER:-false}"
export BRAIN_INCLUDE="${BRAIN_INCLUDE:-}"
export BRAIN_EXCLUDE="${BRAIN_EXCLUDE:-}"

export CATS_NODES="${CATS_NODES:-1}"
export CATS_FLAKE_ATTEMPTS="${CATS_FLAKE_ATTEMPTS:-5}"
export CATS_TIMEOUT_SCALE="${CATS_TIMEOUT_SCALE:-3.0}"


# scf-build relevant:

export SCF_LOCAL="${SCF_LOCAL:-}"

# relevant to several:

export HELM_VERSION="${HELM_VERSION:-v3.1.1}"

export SCF_REPO="${SCF_REPO:-https://github.com/SUSE/scf}"
export SCF_BRANCH="${SCF_BRANCH:-develop}"
