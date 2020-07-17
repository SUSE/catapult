#!/bin/bash

. ../../include/common.sh
. .envrc

info "Generating stratos-metrics config values from stratos values"

KUBE_API_ENDPOINT=$(kubectl config view -o json | jq -r '.clusters[].cluster.server')

cp stratos-config-values.yaml stratos-metrics-config-values.yaml
for patch in "$ROOT_DIR"/modules/metrics/patches/*.yaml; do
    echo "Applying patch $patch"
    trunion -d stratos=stratos-config-values.yaml \
                    -d metrics=stratos-metrics-config-values.yaml \
                    -p "$patch" \
                    > stratos-metrics-config-values_temp.yaml
    mv stratos-metrics-config-values_temp.yaml stratos-metrics-config-values.yaml
done


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
