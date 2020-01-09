#!/usr/bin/env bash

set -exo pipefail

. ../../include/common.sh
. .envrc

set -u

curl -o terraform.zip https://releases.hashicorp.com/terraform/0.12.9/terraform_0.12.9_linux_amd64.zip
unzip terraform.zip
chmod +x terraform && mv terraform bin/
rm -rf terraform.zip
