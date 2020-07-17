#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Generating KubeCF config values"

# generate all old-school env vars:

kubectl patch -n kube-system configmap cap-values -p $'data:\n services: "'$SCF_SERVICES'"'
export services="$SCF_SERVICES"
export domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
echo "$domain"
export public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
array_external_ips=()
while IFS='' read -r line; do array_external_ips+=("$line");
done < <(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address')
external_ips+="\"$public_ip\""
for (( i=0; i < ${#array_external_ips[@]}; i++ )); do
    external_ips+=", \"${array_external_ips[$i]}\""
done
export external_ips

# TODO the (( grab $env_var )) are quoting the vars, weirdly. It doesn't happen for stratos-config-values.yaml

# compute the patches:

cp values.yaml kubecf-config-values.yaml
for patch in "$ROOT_DIR"/modules/kubecf/patches/*.yaml; do
    echo "Applying patch $patch"
    trunion -d kubecf=kubecf-config-values.yaml \
                    -p "$patch" \
                    > kubecf-config-values_temp.yaml
    mv kubecf-config-values_temp.yaml kubecf-config-values.yaml
done

ok "KubeCF config values generated"
