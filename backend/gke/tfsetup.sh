#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ./defaults.sh
. ../../include/common.sh
[[ -d "${BUILD_DIR}" ]] || exit 0
. .envrc


if ! [[ -d cap-terraform ]]; then
    git clone https://github.com/SUSE/cap-terraform.git -b "${CAP_TERRAFORM_BRANCH}"
fi
pushd cap-terraform/gke || exit
git checkout "${CAP_TERRAFORM_BRANCH}"
git pull

# Clear out any existing variables file
cat > terraform.tfvars.json <<HEREDOC
{
    "project"        : "$GKE_PROJECT",
    "location"       : "$GKE_LOCATION",
    "node_pool_name" : "$GKE_CLUSTER_NAME",
    "instance_count" : "$GKE_NODE_COUNT",
    "preemptible"    : "$GKE_PREEMPTIBLE",
    "vm_type"        : "UBUNTU",
    "gke_sa_key"     : "$GKE_CRED_JSON",
    "gcp_dns_sa_key" : "$GKE_DNSCRED_JSON",
    "cluster_labels" : {
        "catapult-clustername": "$GKE_CLUSTER_NAME",
        "owner" : "${OWNER}"
    },
    "cluster_name"   : "$GKE_CLUSTER_NAME",
    "k8s_version"    : "latest"
}
HEREDOC

if [ -n "${EXTRA_LABELS}" ] ; then
    jq --raw-output --argjson labels "${EXTRA_LABELS}" '.cluster_labels *= $labels' terraform.tfvars.json \
        | sponge terraform.tfvars.json
fi

if [ -n "${GKE_INSTANCE_TYPE}" ] ; then
    jq --argjson type "${GKE_INSTANCE_TYPE}" '.instance_type = $type' terraform.tfvars.json \
        | sponge terraform.tfvars.json
fi

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

# terraform needs helm client installed and configured:
helm_init_client
popd || exit
