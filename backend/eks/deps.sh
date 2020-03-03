#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

if [[ "$DOWNLOAD_BINS" == "false" ]]; then
    ok "Skipping downloading deps, using host binaries"
    exit 0
fi


# pin the kubectl to eks default version. Hardcoded as the URL has a changing date stamp
curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl
chmod +x kubectl && mv kubectl bin/

if ! which aws ; then
    mkdir -p .local
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    ./awscli-bundle/install --install-dir=$(pwd)/.local/ --bin-location=$(pwd)/bin/aws
    rm -rf awscli-bundle*

    curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator
    chmod +x aws-iam-authenticator && mv aws-iam-authenticator bin/
fi

curl -o terraform.zip https://releases.hashicorp.com/terraform/0.12.9/terraform_0.12.9_linux_amd64.zip
# curl -o terraform.zip https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
unzip terraform.zip
chmod +x terraform && mv terraform bin/
rm -rf terraform.zip
