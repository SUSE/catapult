#!/bin/bash

. ../../include/common.sh
. .envrc

info "Generating stratos config values from scf values"

cp scf-config-values.yaml scf-config-values-for-stratos.yaml
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

cat <<EOF > op.yml
- op: add
  path: /console
  value:
    service:
      externalIPs: ["${public_ip}"]
      servicePort: 8443
      ingress:
        enabled: true
        host: ${domain}
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

yamlpatch op.yml scf-config-values-for-stratos.yaml

ok "Stratos config values generated"
