#!/usr/bin/env bash

# Requires:
# - aws credentials present

. ./defaults.sh
. ../../include/common.sh
[[ -d "${BUILD_DIR}" ]] || exit 0
. .envrc

if ! [[ -d cap-terraform ]]; then
    git clone https://github.com/SUSE/cap-terraform.git -b "${CAP_TERRAFORM_BRANCH}"
fi
pushd cap-terraform/eks || exit
git checkout "${CAP_TERRAFORM_BRANCH}"
git pull

# terraform needs helm client installed and configured:
helm_init_client

cat <<HEREDOC > terraform.tfvars
cluster_name = "${EKS_CLUSTER_NAME}"
region = "${EKS_LOCATION}"
keypair_name = "${EKS_KEYPAIR}"
eks_version = "${EKS_VERS}"
cluster_labels = ${EKS_CLUSTER_LABEL}
hosted_zone_name = "${EKS_HOSTED_ZONE_NAME}"
external_dns_aws_access_key = "${AWS_ACCESS_KEY_ID}"
external_dns_aws_secret_key = "${AWS_SECRET_ACCESS_KEY}"
deployer_role_arn = "${EKS_DEPLOYER_ROLE_ARN}"
cluster_role_name = "${EKS_CLUSTER_ROLE_NAME}"
cluster_role_arn = "${EKS_CLUSTER_ROLE_ARN}"
worker_node_role_name = "${EKS_WORKER_NODE_ROLE_NAME}"
worker_node_role_arn = "${EKS_WORKER_NODE_ROLE_ARN}"
kube_authorized_role_arn = "${KUBE_AUTHORIZED_ROLE_ARN}"
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
