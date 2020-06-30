#!/usr/bin/env bash

# Dependencies options
######################

# Default versions in case the are undefined in the backend:
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.17.0}"
export HELM_VERSION="${HELM_VERSION:-v3.1.1}"
