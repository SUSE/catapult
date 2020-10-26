#!/usr/bin/env bash

# Common options
##################

OWNER="${OWNER:-$(whoami)}"

# GKE options
#############

GKE_PROJECT="${GKE_PROJECT:-suse-css-platform}"
GKE_LOCATION="${GKE_LOCATION:-europe-west4-a}"
GKE_CLUSTER_NAME="${GKE_CLUSTER_NAME:-${OWNER}-cap}"
GKE_CRED_JSON="${GKE_CRED_JSON:-}"
GKE_DNSCRED_JSON="${GKE_DNSCRED_JSON:-${GKE_CRED_JSON}}"
GKE_NODE_COUNT="${GKE_NODE_COUNT:-3}"
GKE_PREEMPTIBLE="${GKE_PREEMPTIBLE:-false}"
GKE_DNSDOMAIN="${GKE_DNSDOMAIN:-${GKE_CLUSTER_NAME}.ci.kubecf.charmedquarks.me}"

# Instance type of the nodes: empty string for terraform's default, or for example n1-highcpu-16 for 1-node cluster
GKE_INSTANCE_TYPE="${GKE_INSTANCE_TYPE:-}"

# Extra labels to attach to clusters, in terraform syntax.
EXTRA_LABELS="${EXTRA_LABELS:-}"

# Settings for terraform state save/restore
#
# Set to a non-empty key to trigger state save in deploy.sh.
TF_KEY="${TF_KEY:-}"

#
# s3 bucket and bucket region to save state to. Ignored when
# TF_KEY is empty (default, see above).
TF_BUCKET="${TF_BUCKET:-cap-ci-tf}"
TF_REGION="${TF_REGION:-us-west-2}"
