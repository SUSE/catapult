#!/bin/bash

. ../../include/common.sh
. .envrc

info "Generating stratos config values from scf values"

cp scf-config-values.yaml scf-config-values-for-stratos.yaml

cat <<HEREDOC_APPEND >> scf-config-values-for-stratos.yaml

# Appended for stratos:
console:
  service:
    ingress:
      enabled: true
HEREDOC_APPEND

ok "Stratos config values generated"
