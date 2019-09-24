#!/usr/bin/env bash

. scripts/include/common.sh
. .envrc

set -Eeuxo pipefail

curl -Lo kube-ready-state-check.sh "$SCF_REPO"/raw/"$SCF_BRANCH"/bin/dev/kube-ready-state-check.sh
chmod +x kube-ready-state-check.sh
mv kube-ready-state-check.sh bin/

kube-ready-state-check.sh kube
