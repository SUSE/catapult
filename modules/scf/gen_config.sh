#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


info "Generating SCF config values"
if [ "${DEFAULT_STACK}" = "from_chart" ]; then
    export DEFAULT_STACK=$(helm inspect helm/cf/ | grep DEFAULT_STACK | sed  's~DEFAULT_STACK:~~g' | sed 's~"~~g' | sed 's~\s~~g')
fi

if [ "$ENABLE_EIRINI" = false ]; then
  GARDEN_ROOTFS_DRIVER="${GARDEN_ROOTFS_DRIVER:-overlay-xfs}"
fi

domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
aux_external_ips=($(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address'))
external_ips+="\"$public_ip\""
for (( i=0; i < ${#aux_external_ips[@]}; i++ )); do
external_ips+=", \"${aux_external_ips[$i]}\""
done

VALUES=
if [ "$ENABLE_EIRINI" = true ] ; then
  AUTH="rbac"
else
  AUTH="rbac"
  VALUES=$(cat <<'END_HEREDOC'
sizing:
  cc_uploader:
    capabilities: ["SYS_RESOURCE"]
  diego_api:
    capabilities: ["SYS_RESOURCE"]
  diego_brain:
    capabilities: ["SYS_RESOURCE"]
  diego_ssh:
    capabilities: ["SYS_RESOURCE"]
  nats:
    capabilities: ["SYS_RESOURCE"]
  router:
    capabilities: ["SYS_RESOURCE"]
  routing_api:
    capabilities: ["SYS_RESOURCE"]
END_HEREDOC
)

fi

if [ "${SCF_OPERATOR}" == "true" ]; then

cat > scf-config-values.yaml <<EOF
system_domain: $domain

features:
  eirini:
    enabled: ${ENABLE_EIRINI}

${CONFIG_OVERRIDE}

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

else

cat > scf-config-values.yaml <<EOF
env:
  # Enter the domain you created for your CAP cluster
  DOMAIN: "${domain}"
  NGINX_MAX_REQUEST_BODY_SIZE: 4000
  EIRINI_PERSI_PLANS: |
      - id: "default"
        name: "default"
        description: "Eirini persistence broker"
        free: true
        kube_storage_class: "${STORAGECLASS}"
        default_size: "2Gi"

  # UAA host and port
  UAA_HOST: "uaa.${domain}"
  UAA_PORT: 2793
  DEFAULT_STACK: "${DEFAULT_STACK}"
  GARDEN_ROOTFS_DRIVER: "${GARDEN_ROOTFS_DRIVER}"
  KUBE_CSR_AUTO_APPROVAL: true

${CONFIG_OVERRIDE}

${VALUES}
enable:
  eirini: ${ENABLE_EIRINI}
  autoscaler: ${AUTOSCALER}

config:
  HA: ${HA}

EOF
if [ "${HA}" != "true" ]; then
cat >> scf-config-values.yaml <<EOF
sizing:
  uaa:
    count: ${SIZING}
  tcp_router:
    count: ${SIZING}
  syslog_scheduler:
    count: ${SIZING}
  adapter:
    count: ${SIZING}
  api_group:
    count: ${SIZING}
  autoscaler_actors:
    count: 1
  autoscaler_api:
    count: ${SIZING}
  autoscaler_metrics:
    count: ${SIZING}
  autoscaler_postgres:
    count: 1
  bits:
    count: 1
  blobstore:
    count: 1
  cc_clock:
    count: ${SIZING}
  cc_uploader:
    count: ${SIZING}
  cc_worker:
    count: ${SIZING}
  cf_usb_group:
    count: ${SIZING}
  credhub_user:
    count: ${SIZING}
  diego_api:
    count: ${SIZING}
  diego_brain:
    count: ${SIZING}
  diego_cell:
    count: ${DIEGO_SIZING}
  diego_ssh:
    count: ${SIZING}
  doppler:
    count: ${SIZING}
  eirini:
    count: ${SIZING}
  locket:
    count: ${SIZING}
  log_api:
    count: ${SIZING}
  log_cache_scheduler:
    count: ${SIZING}
  loggregator_agent:
    count: ${SIZING}
  mysql:
    count: ${SIZING}
  nats:
    count: ${SIZING}
  nfs_broker:
    count: 1
  post_deployment_setup:
    count: 1
  router:
    count: ${SIZING}
  routing_api:
    count: ${SIZING}
  secret_generation:
    count: 1

EOF
fi
cat >> scf-config-values.yaml <<EOF
kube:
  # The IP address assigned to the kube node pointed to by the domain.
  external_ips: [${external_ips}]

  # Run kubectl get storageclasses
  # to view your available storage classes
  storage_class:
    persistent: "${STORAGECLASS}"
    shared: "${STORAGECLASS}"

  # The registry the images will be fetched from.
  # The values below should work for
  # a default installation from the SUSE registry.
  registry:
    hostname: "${DOCKER_REGISTRY}"
    username: "${DOCKER_USERNAME}"
    password: "${DOCKER_PASSWORD}"
  organization: "${DOCKER_ORG}"
  auth: ${AUTH}

secrets:
  # Create a password for your CAP cluster
  CLUSTER_ADMIN_PASSWORD: ${CLUSTER_PASSWORD}

  # Create a password for your UAA client secret
  UAA_ADMIN_CLIENT_SECRET: ${CLUSTER_PASSWORD}
EOF

fi

ok "SCF config values generated"
