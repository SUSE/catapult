#!/bin/bash

# SCF options
#############

CHART_URL="${CHART_URL:-}" # FIXME deprecated, used in SCF_CHART
SCF_CHART="${SCF_CHART:-$CHART_URL}"
STRATOS_CHART="${STRATOS_CHART:-}"

SCF_HELM_VERSION="${SCF_HELM_VERSION:-}"
SCF_OPERATOR="${SCF_OPERATOR:-false}"
OPERATOR_CHART_URL="${OPERATOR_CHART_URL:-latest}"

GARDEN_ROOTFS_DRIVER="${GARDEN_ROOTFS_DRIVER:-btrfs}"
DIEGO_SIZING="${DIEGO_SIZING:-$SIZING}"
STORAGECLASS="${STORAGECLASS:-persistent}"
AUTOSCALER="${AUTOSCALER:-false}"

EMBEDDED_UAA="${EMBEDDED_UAA:-false}"

HA="${HA:-false}"
if [ "$HA" = "true" ]; then
    SIZING="${SIZING:-2}"
else
    SIZING="${SIZING:-1}"
fi

UAA_UPGRADE="${UAA_UPGRADE:-true}"

OVERRIDE="${OVERRIDE:-}"
CONFIG_OVERRIDE="${CONFIG_OVERRIDE:-$OVERRIDE}"

SCF_LOCAL="${SCF_LOCAL:-}"