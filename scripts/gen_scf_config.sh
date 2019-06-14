#!/bin/bash
set -ex 
pushd build
cluster_name=$(./kind get clusters)
container_id=$(docker ps -f "name=${cluster_name}-control-plane" -q)
container_ip=$(docker inspect $container_id | jq -r .[0].NetworkSettings.Networks.bridge.IPAddress)

DOCKER_REGISTRY="${DOCKER_REGISTRY:-}"
DOCKER_ORG="${DOCKER_ORG:-}"
DOCKER_USERNAME="${DOCKER_USERNAME:-}"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-}"

cat > scf-config-values.yaml <<EOF
env:
  # Enter the domain you created for your CAP cluster
  DOMAIN: ${container_ip}.nip.io
  EIRINI_PERSI_PLANS: |
      - id: "default"
        name: "default"
        description: "Eirini persistence broker"
        free: true
        kube_storage_class: "persistent"
        default_size: "2Gi"

  # UAA host and port
  UAA_HOST: uaa.${container_ip}.nip.io
  UAA_PORT: 2793

enable:
  eirini: true

kube:
  # The IP address assigned to the kube node pointed to by the domain.
  external_ips: ["${container_ip}"]

  # Run kubectl get storageclasses
  # to view your available storage classes
  storage_class:
    persistent: "persistent"
    shared: "shared"

  # The registry the images will be fetched from.
  # The values below should work for
  # a default installation from the SUSE registry.
  registry:
    hostname: "${DOCKER_REGISTRY}"
    username: "${DOCKER_USERNAME}"
    password: "${DOCKER_PASSWORD}"
  organization: "${DOCKER_ORG}"
  auth: rbac

secrets:
  # Create a password for your CAP cluster
  CLUSTER_ADMIN_PASSWORD: password

  # Create a password for your UAA client secret
  UAA_ADMIN_CLIENT_SECRET: password
EOF

