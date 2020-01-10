#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

if [[ "$DOWNLOAD_BINS" == "false" ]]; then
    ok "Skipping downloading deps, using host binaries"
    exit 0
fi

curl -o google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-264.0.0-linux-x86_64.tar.gz
tar -xvf google-cloud-sdk.tar.gz
rm google-cloud-sdk.tar.gz
pushd google-cloud-sdk
bash ./install.sh -q
popd
echo "source $(pwd)/google-cloud-sdk/path.bash.inc" >> .envrc

curl -o terraform.zip https://releases.hashicorp.com/terraform/0.12.9/terraform_0.12.9_linux_amd64.zip
unzip terraform.zip
chmod +x terraform && mv terraform bin/
rm -rf terraform.zip
