#!/bin/bash

. ../../include/common.sh
. .envrc

info "Generating stratos-metrics config values"

KUBE_API_ENDPOINT=$(kubectl config view -o json | jq -r '.clusters[].cluster.server')

cp scf-config-values-for-stratos.yaml scf-config-values-for-metrics.yaml

cat <<EOF > op.yml
- op: add
  path: /prometheus
  value:
    imagePullSecrets:
    - name: regsecret
- op: replace
  path: /kube/registry/hostname
  value:
    "${DOCKER_REGISTRY}"
- op: replace
  path: /kube/registry/username
  value:
    "${DOCKER_USERNAME}"
- op: replace
  path: /kube/registry/password
  value:
    "${DOCKER_PASSWORD}"
- op: replace
  path: /kube/organization
  value:
    "${DOCKER_ORG}"
EOF

yamlpatch op.yml scf-config-values-for-metrics.yaml

cat <<HEREDOC > stratos-metrics-values.yaml
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
