#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [[ "$OSTYPE" == "darwin"* ]]; then
    VM_DRIVER=virtualbox
else
    VM_DRIVER=docker # or kvm2
fi

: "${VM_CPUS:=4}"
: "${VM_MEMORY:=16384}"
: "${VM_DISK_SIZE:=120g}"

: "${MINIKUBE_ISO_VERSION:=0.1.8}"
: "${MINIKUBE_ISO_URL:=https://github.com/f0rmiga/opensuse-minikube-image/releases/download/v${MINIKUBE_ISO_VERSION}/minikube-openSUSE.x86_64-${MINIKUBE_ISO_VERSION}.iso}"

# shellcheck disable=SC2086
minikube start \
         --profile "$CLUSTER_NAME" \
         --kubernetes-version "1.17.5" \
         --insecure-registry "10.0.0.0/24" \
         --cpus "${VM_CPUS}" \
         --memory "${VM_MEMORY}" \
         --disk-size "${VM_DISK_SIZE}" \
         --iso-url "${MINIKUBE_ISO_URL}" \
         ${VM_DRIVER:+--vm-driver "${VM_DRIVER}"} \
         --extra-config=apiserver.runtime-config=settings.k8s.io/v1alpha1=true \
         --extra-config=apiserver.enable-admission-plugins=MutatingAdmissionWebhook,PodPreset \
         ${MINIKUBE_EXTRA_OPTIONS:-}

# Enable hairpin by setting the docker0 promiscuous mode on.
minikube --profile "$CLUSTER_NAME" ssh -- "sudo ip link set docker0 promisc on"

minikube --profile "$CLUSTER_NAME" addons enable dashboard
minikube --profile "$CLUSTER_NAME" addons enable metrics-server

container_ip=$(minikube ip --profile "$CLUSTER_NAME")
domain="${container_ip}.$MAGICDNS"

helm_init

if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=public-ip="${container_ip}" \
            --from-literal=domain="$domain" \
            --from-literal=services="$services" \
            --from-literal=services="hardcoded" \
            --from-literal=platform="minikube"
fi

ok "Minikube is ready"
