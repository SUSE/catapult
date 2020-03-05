#!/usr/bin/env bash

# Minikube backend options
##########################

HELM_VERSION="${HELM_VERSION:-v3.1.1}"
MINIKUBE_RUNTIME=${MINIKUBE_RUNTIME:-docker} # docker, containerd, cri-o
