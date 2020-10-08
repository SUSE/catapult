#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Generating KubeCF config values"
rm -f scf-config-values.yaml

if [ -z "$KUBECF_SERVICES" ]; then
    services=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["services"]')
else
    # KUBECF_SERVICES not empty, we want to override then:
    services="$KUBECF_SERVICES"
fi
domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

if [ "${services}" == "hardcoded" ]; then
    public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
    array_external_ips=()
    while IFS='' read -r line; do array_external_ips+=("$line");
    done < <(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address')
    external_ips+="\"$public_ip\""
    for (( i=0; i < ${#array_external_ips[@]}; i++ )); do
        external_ips+=", \"${array_external_ips[$i]}\""
    done
else
    external_ips=''
fi

if [ "${services}" == "lb" ] || [ "${services}" == "hardcoded" ]; then
    cat >> scf-config-values.yaml <<EOF
#  External endpoints are created for the instance groups only if
#  features.ingress.enabled is false.
services:
  router:
    type: LoadBalancer
    externalIPs: [${external_ips}]
    annotations:
      "external-dns.alpha.kubernetes.io/hostname": "${domain}, *.${domain}"
  ssh-proxy:
    type: LoadBalancer
    externalIPs: [${external_ips}]
    annotations:
      "external-dns.alpha.kubernetes.io/hostname": "ssh.${domain}"
  tcp-router:
    type: LoadBalancer
    externalIPs: [${external_ips}]
    annotations:
      "external-dns.alpha.kubernetes.io/hostname": "*.tcp.${domain}, tcp.${domain}"
    port_range:
      start: 20000
      end: 20008
EOF
fi


INSTALL_STACKS="[sle15, cflinuxfs3]"
if [[ $ENABLE_EIRINI == true ]]; then
    INSTALL_STACKS="[sle15]"
fi

cat >> scf-config-values.yaml <<EOF
system_domain: $domain

install_stacks: ${INSTALL_STACKS}

features:
  eirini:
    enabled: ${ENABLE_EIRINI}
  autoscaler:
    enabled: ${AUTOSCALER}

high_availability: ${HA}

testing:
  brain_tests:
    enabled: true
  cf_acceptance_tests:
    enabled: true
  smoke_tests:
    enabled: true
  sync_integration_tests:
    enabled: true
properties:
  acceptance-tests:
    acceptance-tests:
      acceptance_tests:
        timeout_scale: ${CATS_TIMEOUT_SCALE}
        ginkgo:
          slow_spec_threshold: 300
          extra_flags: "${GINKGO_EXTRA_FLAGS}"
          nodes: ${CATS_NODES}
          flake_attempts: ${CATS_FLAKE_ATTEMPTS}
  brain-tests:
    acceptance-tests-brain:
      acceptance_tests_brain:
        verbose: "${BRAIN_VERBOSE}"
        in_order: "${BRAIN_INORDER}"
        include: "${BRAIN_INCLUDE}"
        exclude: "${BRAIN_EXCLUDE}"
EOF

# Create json structure to make iterative changes
scf_config_values=$(y2j scf-config-values.yaml | jq --compact-output .)

# Create and merge overrides for airgapped deployments
if [[ "${DOCKER_REGISTRY}" != "registry.suse.com" ]]; then
  airgap_overrides=$(y2j << EOF
---
releases:
  defaults:
    url: ${DOCKER_REGISTRY}/${DOCKER_ORG}
  pxc:
    image:
      repository: ${DOCKER_REGISTRY}/${DOCKER_ORG}/pxc
EOF
)
  buildpacks="suse-staticfile-buildpack suse-java-buildpack suse-ruby-buildpack suse-dotnet-core-buildpack suse-nodejs-buildpack suse-go-buildpack suse-python-buildpack suse-php-buildpack suse-nginx-buildpack suse-binary-buildpack"
  for buildpack in ${buildpacks}; do
    buildpack_override=$(y2j << EOF
---
releases:
  ${buildpack}:
    url: ${DOCKER_REGISTRY}/${DOCKER_ORG}
EOF
)
    airgap_overrides=$(jq --compact-output --null-input "${airgap_overrides} * ${buildpack_override}")
  done
  scf_config_values=$(jq --compact-output --null-input "${scf_config_values} * ${airgap_overrides}")
fi


if [ "${services}" == "ingress" ]; then
    ingress_block=$(y2j << EOF
---
features:
  ingress:
    enabled: true
    tls:
      crt:
      key:
    annotations: {}
    labels: {}
EOF
)
    # save ingress cert and key to file
    kubectl get configmap -n kube-system cap-values -o json | \
        jq -r '.data["ingress-cert"]' \
           > ingress-cert
    kubectl get configmap -n kube-system cap-values -o json | \
        jq -r '.data["ingress-cert-key"]' \
           > ingress-cert-key
    # add ingress block
    scf_config_values=$(jq --compact-output --null-input "${scf_config_values} * ${ingress_block}")
    # patch values json with cert and key from file
    scf_config_values=$(echo "$scf_config_values" | jq --compact-output --rawfile crt ./ingress-cert '.features.ingress.tls.crt=$crt')
    scf_config_values=$(echo "$scf_config_values" | jq --compact-output --rawfile key ./ingress-cert-key '.features.ingress.tls.key=$key')
fi



# Ensure CONFIG_OVERRIDE is a json object
CONFIG_OVERRIDE=${CONFIG_OVERRIDE:-"{}"}
CONFIG_OVERRIDE=$(y2j <<< ${CONFIG_OVERRIDE})
# merge current scf config values with overrides
scf_config_values=$(jq --compact-output --null-input "${scf_config_values} * ${CONFIG_OVERRIDE}")

# Convert scf-config-values to yaml and write to file
j2y <<< "${scf_config_values}" > scf-config-values.yaml
ok "KubeCF config values generated"
