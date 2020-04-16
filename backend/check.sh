#!/usr/bin/env bash

. include/common.sh
. .envrc

curl -sSLo bin/kube-ready-state-check.sh \
     https://raw.githubusercontent.com/cloudfoundry-incubator/kubecf/master/dev/kube/kube-ready-state-check.sh
chmod +x bin/kube-ready-state-check.sh

info "Testing imported k8s cluster for kubecf"

kube-ready-state-check.sh kube

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
