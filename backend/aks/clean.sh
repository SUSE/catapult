#!/usr/bin/env bash

# Requires:
# - azure credentials present

. ./defaults.sh
. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
    . .envrc
    # Required env vars for deploying via Azure SP.
    # see: https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html#configuring-the-service-principal-in-terraform
    export ARM_CLIENT_ID="${AZURE_APP_ID}"
    export ARM_CLIENT_SECRET="${AZURE_PASSWORD}"
    export ARM_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
    export ARM_TENANT_ID="${AZURE_TENANT_ID}"

    pushd cap-terraform/aks || exit
    if [[ ! -f aksk8scfg ]]; then
        cp "${KUBECONFIG}" aksk8scfg
    fi
    terraform init
    terraform destroy -auto-approve
    popd || exit
    if az group show --name "${AZURE_RESOURCE_GROUP}" 2>/dev/null; then
        az group delete --name "${AZURE_RESOURCE_GROUP}" --yes
    fi
    rm -rf "$BUILD_DIR"
    ok "AKS cluster deleted successfully"
else
    warn "BUILD_DIR ${BUILD_DIR} not found"
fi

