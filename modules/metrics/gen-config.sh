#!/bin/bash

. ../../include/common.sh
. .envrc

info "Generating stratos-metrics config values"

cat <<HEREDOC_APPEND >> scf-config-values-for-stratos.yaml

# Appended for stratos-metrics:
prometheus:
  imagePullSecrets:
  - name: regsecret
HEREDOC_APPEND


KUBE_API_ENDPOINT=$(kubectl config view -o json | jq -r '.clusters[].cluster.server' | cut -d ':' -f 1,2)":7443"

cat <<HEREDOC > stratos-metrics-values.yaml

# Appended for stratos:
---
env:
  DOPPLER_PORT: 443
kubernetes:
  apiEndpoint: "${KUBE_API_ENDPOINT}"
prometheus:
  kubeStateMetrics:
    enabled: true
nginx:
  username: username
  password: password
services:
  loadbalanced: true
HEREDOC

ok "Stratos-metrics config values generated"
