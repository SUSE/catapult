#!/usr/bin/env bash

# Requires:
# - azure credentials present

. ./defaults.sh
. ../../include/common.sh

set -exuo pipefail

if [ -d "$BUILD_DIR" ]; then
    . .envrc
    if [ -f "$TFSTATE" ]; then
        mkdir -p cap-terraform/aks
        (cd cap-terraform/aks || exit
          # ATTENTION: The next command overwrites existing files without prompting.
          unzip -o "$TFSTATE"
          sed -i "s|client_id.*|client_id=\"${AZURE_APP_ID}\"|" terraform.tfvars
          sed -i "s|client_secret.*|client_secret=\"${AZURE_PASSWORD}\"|" terraform.tfvars
          sed -i "s|azure_dns_json.*|azure_dns_json=\"${AZURE_DNS_JSON}\"|" terraform.tfvars
        )
    fi
    if [ -d "cap-terraform/aks" ]; then
        pushd cap-terraform/aks || exit
        terraform destroy -auto-approve
        popd || exit
    fi

    popd || exit
    rm -rf "$BUILD_DIR"
fi

ok "AKS cluster deleted successfully"
