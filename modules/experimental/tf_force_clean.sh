#!/bin/bash

# Takes an aks, gke, or eks cluster by CLUSTER_NAME and destroys it with terraform

. ./defaults.sh

# BACKEND needs to be set before common script is run, or it defaults to kind
if [[ "${CLUSTER_NAME}" =~ -aks- ]]; then
    export BACKEND=aks
elif [[ "${CLUSTER_NAME}" =~ -gke- ]]; then
    export BACKEND=gke
elif [[ "${CLUSTER_NAME}" =~ -eks- ]]; then
    export BACKEND=eks
fi

if [[ "${BACKEND}" =~ ^aks$|^gke$ ]] && ! [[ -f "${KUBECFG}" ]]; then
    err "KUBECFG must be set to path of valid kubeconfig for ${CLUSTER_NAME} for GKE and AKS backends"
    warn "If this cluster was created via CI, you can obtain this by hijacking the build, or checking the pools repo"
    exit 1
fi
. ../../include/common.sh
if [[ -z "${CLUSTER_NAME}" ]]; then
    err "module-experimental-tf-force-clean requires CLUSTER_NAME to be set"
    exit 1
elif ! [[ "${BACKEND}" =~ ^(aks|gke|eks)$ ]]; then
    err "module-experimental-tf-force-clean requires CLUSTER_NAME to contain '-aks-', '-gke-', or '-eks-', or for BACKEND to be set to aks/gke/eks"
    exit 1
fi

cd "${ROOT_DIR}"
make common-deps
cd "${BUILD_DIR}"
rm -rf cap-terraform
. .envrc

git clone https://github.com/suse/cap-terraform -b "${CAP_TERRAFORM_BRANCH}"
cd "cap-terraform/${BACKEND}"
ARN="$(aws iam get-user --query User.Arn --output text | sed 's@:user/.*@:role/eksServiceRole@')"
aws eks update-kubeconfig --name Concourse --region eu-central-1 --role-arn "${ARN}" --kubeconfig "${KUBECONFIG}"
if [[ "${BACKEND}" == aks ]]; then
    kubectl get secrets -n concourse-main -o json azure-dns-json | jq -r .data.value | base64 -d > azure-dns-key.json
    export AZURE_DNS_JSON_PATH=$PWD/azure-dns-key.json
    export AZURE_APP_ID=$(kubectl get secrets -n concourse-main -o json azure-sp-creds | jq -r .data.app_id | base64 -d)
    export AZURE_PASSWORD=$(kubectl get secrets -n concourse-main -o json azure-sp-creds | jq -r .data.password | base64 -d)
    export AZURE_TENANT_ID=$(kubectl get secrets -n concourse-main -o json azure-sp-creds | jq -r .data.tenant_id | base64 -d)
    export AZURE_SUBSCRIPTION_ID=$(kubectl get secrets -n concourse-main -o json azure-sp-creds | jq -r .data.subscription_id | base64 -d)
    export AZURE_DNS_JSON=${AZURE_DNS_JSON_PATH}
    export AZURE_RESOURCE_GROUP=${CLUSTER_NAME}-rg
    export AZURE_CLUSTER_NAME=${CLUSTER_NAME}
    cp "${KUBECFG}" "${KUBECONFIG}"
elif [[ "${BACKEND}" == eks ]]; then
    export EKS_DEPLOYER_ROLE_ARN=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["deployer-role-arn"]' | base64 -d)
    export EKS_CLUSTER_ROLE_NAME=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["cluster-role-name"]' | base64 -d)
    export EKS_CLUSTER_ROLE_ARN=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["cluster-role-arn"]' | base64 -d)
    export EKS_WORKER_NODE_ROLE_NAME=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["worker-node-role-name"]' | base64 -d)
    export EKS_WORKER_NODE_ROLE_ARN=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["worker-node-role-arn"]' | base64 -d)
    export EKS_CLUSTER_NAME=${CLUSTER_NAME}
    export KUBE_AUTHORIZED_ROLE_ARN=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["kube-authorized-role-arn"]' | base64 -d)
    ci_access_key_id=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["access-key"]'  | base64 -d)
    ci_secret_key=$(kubectl get secrets -n concourse-main -o json aws-service-account-ci-creds | jq -r '.data["secret-key"]'  | base64 -d)
    export AWS_ACCESS_KEY_ID=${ci_access_key_id}
    export AWS_SECRET_ACCESS_KEY=${ci_secret_key}
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
    export GKE_CREDS_JSON=$PWD/gke-key.json
    cp "${KUBECFG}" "${KUBECONFIG}"
fi
export TF_KEY=${CLUSTER_NAME}
cd "${ROOT_DIR}"
make clean
