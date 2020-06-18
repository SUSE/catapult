#!/bin/bash

# KUBECF options
################

# kubecf-chart revelant:

CHART_URL="${CHART_URL:-}" # FIXME deprecated, used in SCF_CHART
SCF_CHART="${SCF_CHART:-$CHART_URL}"

SCF_HELM_VERSION="${SCF_HELM_VERSION:-}"
OPERATOR_CHART_URL="${OPERATOR_CHART_URL:-latest}"

# kubecf-gen-config relevant:

SCF_SERVICES="${SCF_SERVICES:-lb}" # lb, ingress
GARDEN_ROOTFS_DRIVER="${GARDEN_ROOTFS_DRIVER:-overlay-xfs}"
DIEGO_SIZING="${DIEGO_SIZING:-$SIZING}"
STORAGECLASS="${STORAGECLASS:-persistent}"
AUTOSCALER="${AUTOSCALER:-false}"

HA="${HA:-false}"
if [ "$HA" = "true" ]; then
    SIZING="${SIZING:-2}"
else
    SIZING="${SIZING:-1}"
fi

UAA_UPGRADE="${UAA_UPGRADE:-true}"

OVERRIDE="${OVERRIDE:-}"
CONFIG_OVERRIDE="${CONFIG_OVERRIDE:-$OVERRIDE}"

BRAIN_VERBOSE="${BRAIN_VERBOSE:-false}"
BRAIN_INORDER="${BRAIN_INORDER:-false}"
BRAIN_INCLUDE="${BRAIN_INCLUDE:-}"
BRAIN_EXCLUDE="${BRAIN_EXCLUDE:-}"

CATS_NODES="${CATS_NODES:-1}"
GINKGO_EXTRA_FLAGS="${GINKGO_EXTRA_FLAGS:-}"
CATS_FLAKE_ATTEMPTS="${CATS_FLAKE_ATTEMPTS:-5}"
CATS_TIMEOUT_SCALE="${CATS_TIMEOUT_SCALE:-3.0}"


# kubecf-build relevant:

SCF_LOCAL="${SCF_LOCAL:-}"

# relevant to several:

HELM_VERSION="${HELM_VERSION:-v3.1.1}"

SCF_REPO="${SCF_REPO:-https://github.com/cloudfoundry-incubator/kubecf}"
SCF_BRANCH="${SCF_BRANCH:-master}"

# klog relevant:

KUBECF_NAMESPACE="${KUBECF_NAMESPACE:-scf}"
