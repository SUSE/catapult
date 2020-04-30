#!/usr/bin/env bash

# Requires:
# - gcloud credentials present

. ../../include/common.sh

set -exuo pipefail


if [ -d "$BUILD_DIR" ]; then
    . .envrc

    if [ -f "$TFSTATE" ]; then
        mkdir -p cap-terraform/gke
        (cd cap-terraform/gke || exit
          # ATTENTION: The next command overwrites existing files without
          # prompting.
          unzip -o "$TFSTATE"
          sed -i "s|gke_sa_key.*|gke_sa_key=\"${GKE_CRED_JSON}\"|" terraform.tfvars
          sed -i "s|gcp_dns_sa_key.*|gcp_dns_sa_key=\"${GKE_CRED_JSON}\"|" terraform.tfvars
        )
    fi
    if [ -d "cap-terraform/gke" ]; then
        pushd cap-terraform/gke || exit
        terraform destroy -auto-approve
        popd || exit
    fi

    popd || exit
    rm -rf "$BUILD_DIR"
fi
