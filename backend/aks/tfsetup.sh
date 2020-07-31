#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
[[ -d "${BUILD_DIR}" ]] || exit 0
. .envrc

if ! [[ -d cap-terraform ]]; then
    git clone https://github.com/SUSE/cap-terraform.git -b cap-ci
fi
pushd cap-terraform/aks || exit
git checkout cap-ci
git pull 

# terraform needs helm client installed and configured:
helm_init_client

# Note, ssh-key.pub is generated in deploy, and will be lost in ci deployments unless persisted somewhere
cat <<HEREDOC > terraform.tfvars
cluster_name      = "${AZURE_CLUSTER_NAME}"
az_resource_group = "${AZURE_RESOURCE_GROUP}"
client_id         = "${AZURE_APP_ID}"
client_secret     = "${AZURE_PASSWORD}"
ssh_public_key    = "./sshkey.pub"
instance_count    = "${AZURE_NODE_COUNT}"
location          = "${AZURE_LOCATION}"
agent_admin       = "cap-admin"
cluster_labels    = {
    "catapult-cluster" = "${AZURE_CLUSTER_NAME}",
    "owner"            = "${OWNER}"
}
k8s_version       = "${KUBECTL_VERSION#v}"
azure_dns_json    = "${AZURE_DNS_JSON}"
dns_zone_rg       = "${AZURE_DNS_RESOURCE_GROUP}"
HEREDOC

if [ -n "${TF_KEY}" ] ; then
    cat > backend.tf <<EOF
terraform {
  backend "s3" {
      bucket = "${TF_BUCKET}"
      region = "${TF_REGION}"
      key    = "${TF_KEY}"
  }
}
EOF
fi
popd
