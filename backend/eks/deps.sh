#!/usr/bin/env bash

. ../../include/common.sh
[[ -d "${BUILD_DIR}" ]] || exit 0
. .envrc

if [[ "$DOWNLOAD_CATAPULT_DEPS" == "false" ]]; then
    ok "Skipping downloading EKS deps, using host binaries"
    exit 0
fi



awskubectlpath=bin/kubectl
if [ ! -e "$awskubectlpath" ]; then
    # pin the kubectl to eks default version. Hardcoded as the URL has a changing date stamp
    curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl
    chmod +x kubectl && mv kubectl bin/
fi

awspath=bin/aws
if [ ! -e "$awspath" ]; then
    mkdir -p .local
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    ./awscli-bundle/install --install-dir="$(pwd)"/.local/ --bin-location="$(pwd)"/bin/aws
    rm -rf awscli-bundle*
fi

awsiampath=bin/aws-iam-authenticator
if [ ! -e "$awsiampath" ]; then
    curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator
    chmod +x aws-iam-authenticator && mv aws-iam-authenticator bin/
fi

terraformpath=bin/terraform
if [ ! -e "$terraformpath" ]; then
    curl -o terraform.zip https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip
    unzip terraform.zip && rm -rf terraform.zip
    chmod +x terraform && mv terraform bin/
fi
