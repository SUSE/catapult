#!/usr/bin/env bash


. ../../include/common.sh
. .envrc


minikube start --profile "$CLUSTER_NAME"
