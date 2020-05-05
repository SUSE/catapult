#!/usr/bin/env bash

# GKE options
#############

GKE_PROJECT="${GKE_PROJECT:-suse-css-platform}"
GKE_LOCATION="${GKE_LOCATION:-europe-west4-a}"
GKE_CLUSTER_NAME="${GKE_CLUSTER_NAME:-$(whoami)-$CLUSTER_NAME}"
GKE_CRED_JSON="${GKE_CRED_JSON:-}"
GKE_NODE_COUNT="${GKE_NODE_COUNT:-3}"
GKE_DNSDOMAIN="${GKE_DNSDOMAIN:-$GKE_CLUSTER_NAME.ci.kubecf.charmedquarks.me}"

HELM_VERSION="${HELM_VERSION:-v3.1.1}"
