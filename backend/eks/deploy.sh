#!/usr/bin/env bash

# Requires:
# - aws credentials present

. ./defaults.sh
. ../../include/common.sh
. .envrc

if ! aws sts get-caller-identity ; then
    info "Missing aws credentials, running aws configure…"
    # Use predefined aws env vars
    # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
    aws configure
fi

git clone https://github.com/SUSE/cap-terraform.git -b cap-ci
pushd cap-terraform/eks || exit

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

terraform init
terraform plan -out=my-plan

if [ -n "${TF_KEY}" ] ; then
    zip -r9  "${BUILD_DIR}/tf-setup.zip" .
fi

terraform apply -auto-approve my-plan

# get kubectl for eks:
# aws eks --region "$EKS_LOCATION" update-kubeconfig --name "$EKS_CLUSTER_NAME"
# or:
terraform output kubeconfig > "$KUBECONFIG"

# wait for cluster ready:
wait_ns kube-system

# test deployment:
kubectl get svc

ROOTFS=overlay-xfs
# take first worker node as public ip:
PUBLIC_IP="$(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address' | head -n 1)"
if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=garden-rootfs-driver="${ROOTFS}" \
            --from-literal=public-ip="${PUBLIC_IP}" \
            --from-literal=domain="${EKS_DOMAIN}" \
            --from-literal=platform=eks
fi

create_rolebinding() {

    kubectl create clusterrolebinding admin --clusterrole=cluster-admin --user=system:serviceaccount:kube-system:default
    kubectl create clusterrolebinding uaaadmin --clusterrole=cluster-admin --user=system:serviceaccount:uaa:default
    kubectl create clusterrolebinding scfadmin --clusterrole=cluster-admin --user=system:serviceaccount:scf:default

    kubectl apply -f - <<HEREDOC
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: cluster-admin
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-system:default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: kube-system
HEREDOC
}
create_rolebinding
