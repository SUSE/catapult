#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


info "Generating KubeCF config values"

kubectl patch -n kube-system configmap cap-values -p $'data:\n services: "'$SCF_SERVICES'"'
services="$SCF_SERVICES"
domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
array_external_ips=()
while IFS='' read -r line; do array_external_ips+=("$line");
done < <(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address')
external_ips+="\"$public_ip\""
for (( i=0; i < ${#array_external_ips[@]}; i++ )); do
external_ips+=", \"${array_external_ips[$i]}\""
done

if [ "$services" == ingress ]; then
INGRESS_BLOCK="ingress:
    enabled: true
    tls:
      crt: ~
      key: ~
    annotations: {}
    labels: {}
"
else
INGRESS_BLOCK=''
fi

cat > kubecf-config-values.yaml <<EOF
system_domain: $domain

features:
  eirini:
    enabled: ${ENABLE_EIRINI}
  autoscaler:
    enabled: ${AUTOSCALER}
  ${INGRESS_BLOCK}

kube:
  service_cluster_ip_range: 0.0.0.0/0
  pod_cluster_ip_range: 0.0.0.0/0

  registry:
    hostname: "${DOCKER_REGISTRY}"
    username: "${DOCKER_USERNAME}"
    password: "${DOCKER_PASSWORD}"
  organization: "${DOCKER_ORG}"

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

if [ "${services}" == "lb" ]; then
    cat >> kubecf-config-values.yaml <<EOF
#  External endpoints are created for the instance groups only if
#  features.ingress.enabled is false.
services:
  router:
    type: LoadBalancer
    externalIPs: [${external_ips}]
  ssh-proxy:
    type: LoadBalancer
    externalIPs: [${external_ips}]
  tcp-router:
    type: LoadBalancer
    externalIPs: [${external_ips}]
    port_range:
      start: 20000
      end: 20008
EOF
fi

# CONFIG_OVERRIDE last, to actually override
cat >> kubecf-config-values.yaml <<EOF
${CONFIG_OVERRIDE}
EOF

ok "KubeCF config values generated"
