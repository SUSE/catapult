#!/usr/bin/env bash

# EKS options
#############

EKS_LOCATION="${EKS_LOCATION:-us-west-2}"
EKS_KEYPAIR="${EKS_KEYPAIR:-$(whoami)-terraform}"
EKS_VERS="${EKS_VERS:-1.14}"
EKS_CLUSTER_LABEL=${EKS_CLUSTER_LABEL:-\{key = \"$(whoami)-eks-cluster\"\}}
HELM_VERSION="${HELM_VERSION:-v3.1.1}"
# EKS_KUBECTL_VERSION not to be defined as the eks kubectl is hardcoded in deps.sh

# Settings for terraform state save/restore
#
# Set to a non-empty key to trigger state save in deploy.sh.
TF_KEY="${TF_KEY:-}"
#
# s3 bucket and bucket region to save state to. Ignored when
# TF_KEY is empty (default, see above).
TF_BUCKET="${TF_BUCKET:-cap-ci-tf}"
TF_REGION="${TF_REGION:-${EKS_LOCATION}}"

# DNS information (Route53). No defaults. Required.
#EKS_ZONE_ID
#EKS_ZONE_NAME
#EKS_ZONE_POLICY
