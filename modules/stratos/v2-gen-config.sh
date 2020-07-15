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
- op: add
  path: /services
  value:
    loadbalanced: true
EOF

# to be replaced:
cat <<EOF > docker-registry-catapult.yaml
kube:
  registry:
    hostname: "${DOCKER_REGISTRY}"
    username: "${DOCKER_USERNAME}"
    password: "${DOCKER_PASSWORD}"
  organization: "${DOCKER_ORG}"
EOF

# to be added
cat <<EOF > op.yml
console:
  service:
    # externalIPs: ["${public_ip}"]
    externalIPs: (( grab services.router.externalIPs ))
    servicePort: 8443
    ingress:
      enabled: true
      host: "${domain}"
services:
  loadbalanced: true
EOF

spruce merge scf-config-values.yaml docker-registry-catapult.yaml > scf-config-values-for-stratos.yaml
spruce merge scf-config-values-for-stratos.yaml op.yaml > scf-config-values-for-stratos.yaml

ok "Stratos config values generated"



## extract.yaml
system_domain: (( grab scf-values#/system_domain ))
foo: (( grab stratos-values#/system_domain ))

## extract1.yaml
system_domain: (( grab system_domain ))
## extract2.yaml
foo: (( grab system_domain ))
