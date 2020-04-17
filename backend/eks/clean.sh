#!/usr/bin/env bash

# Requires:
# - aws credentials present

. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
    . .envrc

    # TODO: Get this as terraform output
    # Currently assumes an exact structure of the kubeconfig
    eks_cluster_name="$(cat kubeconfig \
                    | yq '.users[0].user.exec.args[2]' \
                    2>/dev/null|head -n1)"

    # See above, having it as proper terraform output is better.
    # if [ -d "cap-terraform/eks" ]; then
    #     eks_cluster_name="$(cd cap-terraform/eks ; terraform output cluster_name)"
    # fi

    eksctl delete cluster --name "${eks_cluster_name}"

    # Activate if eksctl is good
    # if [ -d "cap-terraform/eks" ]; then
    #     rm -rf cap-terraform
    # fi

    # Old code disabled
    # if [ -d "cap-terraform/eks" ]; then
    #     pushd cap-terraform/eks || exit
    #     terraform destroy -auto-approve
    #     popd || exit
    #     rm -rf cap-terraform
    # fi

    popd || exit
    rm -rf "$BUILD_DIR"
fi
