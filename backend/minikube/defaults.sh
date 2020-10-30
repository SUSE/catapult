#!/usr/bin/env bash

# Minikube backend options
##########################

MINIKUBE_RUNTIME=${MINIKUBE_RUNTIME:-docker} # docker, containerd, cri-o
CLUSTER_SERVICES=${CLUSTER_SERVICES:-hardcoded} # hardcoded, or ingress
