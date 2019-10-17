#!/usr/bin/env bash

set -exo pipefail

. ../../include/common.sh
. .envrc

set -u

curl -o helm https://get.helm.sh/helm-v2.12.3-linux-amd64.tar.gz
chmod +x helm && mv helm bin/
