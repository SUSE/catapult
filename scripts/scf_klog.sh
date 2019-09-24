#!/usr/bin/env bash

. scripts/include/common.sh
. .envrc

set -Eeuxo pipefail

curl -Lo kube-ready-state-check.sh "$SCF_REPO"/raw/"$SCF_BRANCH"/bin/dev/kube-ready-state-check.sh

curl -Lo klog.sh "$SCF_REPO"/raw/"$SCF_BRANCH"/container-host-files/opt/scf/bin/klog.sh
chmod +x klog.sh
mv klog.sh bin/

klog.sh
