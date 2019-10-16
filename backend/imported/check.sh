#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

set -Eeuxo pipefail
debug_mode

curl -Lo kube-ready-state-check.sh "$SCF_REPO"/raw/"$SCF_BRANCH"/bin/dev/kube-ready-state-check.sh
chmod +x kube-ready-state-check.sh
mv kube-ready-state-check.sh bin/

info "Testing imported k8s cluster"

kube-ready-state-check.sh kube

info "Adding cap-values configmap if missing"

ROOTFS=overlay-xfs
# take first worker node as public ip:
PUBLIC_IP="$(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address' | head -n 1)"
DOMAIN="$PUBLIC_IP.omg.howdoi.website"
if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=garden-rootfs-driver="${ROOTFS}" \
            --from-literal=public-ip="${PUBLIC_IP}" \
            --from-literal=domain="${DOMAIN}" \
            --from-literal=platform=imported
fi

ok "k8s cluster imported successfully"
