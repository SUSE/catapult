#!/usr/bin/env bash

. include/common.sh
. .envrc

curl -s -Lo kube-ready-state-check.sh https://github.com/cloudfoundry-incubator/kubecf/raw/master/bin/dev/kube-ready-state-check.sh
chmod +x kube-ready-state-check.sh
mv kube-ready-state-check.sh bin/

info "Testing imported k8s cluster"

kube-ready-state-check.sh kube || true

info "Adding cap-values configmap if missing"
if ! kubectl get configmap cap-values -n kube-system 2>/dev/null | grep -qi cap-values; then
    ROOTFS=overlay-xfs
    # take first worker node as public ip:
    PUBLIC_IP="$(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address' | head -n 1)"
    DOMAIN="$PUBLIC_IP.$MAGICDNS"
    if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
        kubectl create configmap -n kube-system cap-values \
                --from-literal=garden-rootfs-driver="${ROOTFS}" \
                --from-literal=public-ip="${PUBLIC_IP}" \
                --from-literal=domain="${DOMAIN}" \
                --from-literal=platform="${BACKEND}"
    fi
fi

info "Initializing helm client"
helm_init

ok "k8s cluster imported successfully"
