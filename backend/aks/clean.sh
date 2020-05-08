#!/usr/bin/env bash

# Requires:
# - azure credentials present

. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
    . .envrc

    if [ -d "cap-terraform/aks" ]; then

	KUBECONFIG="$(pwd)"/cap-terraform/aks/aksk8scfg

        pushd cap-terraform/aks || exit
        terraform destroy -auto-approve
        popd || exit
    fi

    popd || exit
    rm -rf "$BUILD_DIR"
fi

ok "AKS cluster deleted successfully"
