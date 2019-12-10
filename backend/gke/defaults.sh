#!/usr/bin/env bash

# GKE options
#############

GKE_PROJECT="${GKE_PROJECT:-suse-css-platform}"
GKE_LOCATION="${GKE_LOCATION:-europe-west4-a}"
GKE_CLUSTER_NAME="${GKE_CLUSTER_NAME:-$(whoami)-cap}"
GKE_CRED_JSON="${GKE_CRED_JSON:-}"
