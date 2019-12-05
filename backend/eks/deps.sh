#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

# pin the kubectl to eks default version
curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.8/2019-08-14/bin/linux/amd64/kubectl
chmod +x kubectl && mv kubectl bin/

# pin helm to cap-terraform/eks/modules/eks/<tiller image> version
curl -o helm.tar.gz https://get.helm.sh/helm-v2.12.3-linux-amd64.tar.gz
tar -xvf helm.tar.gz
chmod +x helm && mv helm bin/
rm -rf helm.tar.gz

mkdir -p .local
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install --install-dir=$(pwd)/.local/ --bin-location=$(pwd)/bin/aws
rm -rf awscli-bundle*

curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator
chmod +x aws-iam-authenticator && mv aws-iam-authenticator bin/

curl -o terraform.zip https://releases.hashicorp.com/terraform/0.12.9/terraform_0.12.9_linux_amd64.zip
# curl -o terraform.zip https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
unzip terraform.zip
chmod +x terraform && mv terraform bin/
rm -rf terraform.zip
