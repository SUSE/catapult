#!/bin/bash

. ../../include/common.sh
. .envrc

set -Eexuo pipefail
debug_mode

info "Generating stratos config values from scf values"

cp scf-config-values.yaml scf-config-values-for-stratos.yaml

cat <<HEREDOC_APPEND >> scf-config-values-for-stratos.yaml

# Appended for stratos:

kube:
  registry:
    hostname: "${DOCKER_REGISTRY}"
    username: "${DOCKER_USERNAME}"
    password: "${DOCKER_PASSWORD}"
HEREDOC_APPEND

ok "Stratos config values generated"
