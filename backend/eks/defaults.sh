#!/usr/bin/env bash

# EKS options
#############

EKS_LOCATION="${EKS_LOCATION:-us-west-2}"
EKS_KEYPAIR="${EKS_KEYPAIR:-$(whoami)-terraform}"
EKS_VERS="${EKS_VERS:-1.14}"
EKS_CLUSTER_LABEL=${EKS_CLUSTER_LABEL:-\{key = \"$(whoami)-eks-cluster\"\}}
HELM_VERSION="${HELM_VERSION:-v2.16.1}"
# EKS_KUBECTL_VERSION not to be defined as the eks kubectl is hardcoded in deps.sh
