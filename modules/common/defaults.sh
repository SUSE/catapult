#!/usr/bin/env bash

# Common options
##################

# Cluster owner (for metadata)
OWNER="${OWNER:-$(whoami)}"

# Dependencies options
######################

# Default versions in case the are undefined in the backend:
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.17.0}"
HELM_VERSION="${HELM_VERSION:-v3.2.4}"
