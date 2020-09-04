#!/bin/bash

# Deploys an eks/aks/gke cluster with values taken from concourse secrets. For local use, but deploys a k8s cluster like CI

if [[ -n "${CLUSTER_NAME}" ]]; then
    echo "module-experimental-tf-auto-deploy requires CLUSTER_NAME to be unset"
    exit 1
fi
. ../../include/common.sh
unset BUILD_DIR

if ! [[ "${BACKEND}" =~ ^(aks|gke|eks)$ ]]; then
    err "module-experimental-tf-force-clean requires BACKEND to be set to aks/gke/eks"
    exit 1
fi

if [[ "${BACKEND}" == gke ]]; then
    warn "tf-auto-deploy may not work with GKE"
fi

random_variable=$(hexdump -n 8 -e '2/4 "%08x"' /dev/urandom)
export CLUSTER_NAME=${BACKEND}-${random_variable}
# Need to source common again after setting CLUSTER_NAME
. $ROOT_DIR/include/common.sh
. $ROOT_DIR/backend/$BACKEND/defaults.sh

cd "${ROOT_DIR}" || exit
make common-deps
cd "${BUILD_DIR}" || exit
. .envrc

git clone https://github.com/suse/cap-terraform -b "${CAP_TERRAFORM_BRANCH}"
cd "cap-terraform/${BACKEND}" || exit
ARN="$(aws iam get-user --query User.Arn --output text | sed 's@:user/.*@:role/eksServiceRole@')"
aws eks update-kubeconfig --name Concourse --region eu-central-1 --role-arn "${ARN}" --kubeconfig "${KUBECONFIG}"
if [[ "${BACKEND}" == aks ]]; then
    kubectl get secrets -n concourse-main -o json azure-dns-json | jq -r .data.value | base64 -d > azure-dns-key.json
    export AZURE_DNS_JSON_PATH AZURE_APP_ID AZURE_PASSWORD AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID AZURE_DNS_JSON AZURE_RESOURCE_GROUP AZURE_CLUSTER_NAME
    AZURE_DNS_JSON_PATH=$PWD/azure-dns-key.json
    AZURE_APP_ID=$(kubectl get secrets -n concourse-main -o json azure-sp-creds | jq -r .data.app_id | base64 -d)
    AZURE_PASSWORD=$(kubectl get secrets -n concourse-main -o json azure-sp-creds | jq -r .data.password | base64 -d)
    AZURE_TENANT_ID=$(kubectl get secrets -n concourse-main -o json azure-sp-creds | jq -r .data.tenant_id | base64 -d)
    AZURE_SUBSCRIPTION_ID=$(kubectl get secrets -n concourse-main -o json azure-sp-creds | jq -r .data.subscription_id | base64 -d)
    AZURE_DNS_JSON=${AZURE_DNS_JSON_PATH}
    AZURE_RESOURCE_GROUP=${CLUSTER_NAME}-rg
    AZURE_CLUSTER_NAME=${CLUSTER_NAME}
elif [[ "${BACKEND}" == eks ]]; then
    export EKS_DEPLOYER_ROLE_ARN EKS_CLUSTER_ROLE_NAME EKS_CLUSTER_ROLE_ARN EKS_WORKER_NODE_ROLE_NAME EKS_WORKER_NODE_ROLE_ARN EKS_CLUSTER_NAME KUBE_AUTHORIZED_ROLE_ARN AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY EKS_KEYPAIR
    EKS_DEPLOYER_ROLE_ARN=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["deployer-role-arn"]' | base64 -d)
    EKS_CLUSTER_ROLE_NAME=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["cluster-role-name"]' | base64 -d)
    EKS_CLUSTER_ROLE_ARN=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["cluster-role-arn"]' | base64 -d)
    EKS_WORKER_NODE_ROLE_NAME=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["worker-node-role-name"]' | base64 -d)
    EKS_WORKER_NODE_ROLE_ARN=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["worker-node-role-arn"]' | base64 -d)
    EKS_CLUSTER_NAME=${CLUSTER_NAME}
    KUBE_AUTHORIZED_ROLE_ARN=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["kube-authorized-role-arn"]' | base64 -d)
    ci_access_key_id=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["access-key"]'  | base64 -d)
    ci_secret_key=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["secret-key"]'  | base64 -d)
    AWS_ACCESS_KEY_ID=${ci_access_key_id}
    AWS_SECRET_ACCESS_KEY=${ci_secret_key}
    EKS_KEYPAIR=ssh-key-ci
    # The following work would assume the EKS_DEPLOYER role and generate a useable kubeconfig. However, a kubeconfig isn't needed to run tf destroy for EKS.
    # Leaving commented out for reference purposes
    # assumed_role=$(aws sts assume-role --role-arn ${EKS_DEPLOYER_ROLE_ARN} --role-session-name RoleTest)
    # export AWS_ACCESS_KEY_ID=$(jq -r .Credentials.AccessKeyId <<< "${assumed_role}")
    # export AWS_SECRET_ACCESS_KEY=$(jq -r .Credentials.SecretAccessKey <<< "${assumed_role}")
    # export AWS_SESSION_TOKEN=$(jq -r .Credentials.SessionToken <<< "${assumed_role}")
    # aws eks update-kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG}"
    # unset AWS_SESSION_TOKEN
    # export AWS_ACCESS_KEY_ID=${ci_access_key_id}
    # export AWS_SECRET_ACCESS_KEY=${ci_secret_key}
else
    kubectl get secrets -n concourse-main -o json gke-key-json | jq -r .data.value | base64 -d > gke-key.json
    export GKE_CREDS_JSON
    GKE_CREDS_JSON=$PWD/gke-key.json
fi
export TF_KEY=${CLUSTER_NAME}
cd "${ROOT_DIR}" || exit
make k8s
