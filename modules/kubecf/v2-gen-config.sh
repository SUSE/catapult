#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Generating KubeCF config values"

cp values.yaml kubecf-config-values.yaml
for patch in "$ROOT_DIR"/modules/kubecf/patches/*.yaml; do
    selective-merge -d kubecf=kubecf-config-values.yaml \
                    -p "$patch" \
                    > kubecf-config-values_temp.yaml
    mv kubecf-config-values_temp.yaml kubecf-config-values.yaml
done

ok "KubeCF config values generated"
exit

########

info "Generating KubeCF config values"

kubectl patch -n kube-system configmap cap-values -p $'data:\n services: "'$SCF_SERVICES'"'
services="$SCF_SERVICES"
domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
# array_external_ips=()
# while IFS='' read -r line; do array_external_ips+=("$line");
# done < <(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address')
external_ips+="\"$public_ip\""
# for (( i=0; i < ${#array_external_ips[@]}; i++ )); do
# external_ips+=", \"${array_external_ips[$i]}\""
# done

if [ "$services" == ingress ]; then
INGRESS_BLOCK="ingress:
    enabled: true
    tls:
      crt: ~
      key: ~
    annotations: {}
    labels: {}
"
else
INGRESS_BLOCK=''
fi

cat > scf-config-values.yaml <<EOF
system_domain: $domain

features:
  eirini:
    enabled: ${ENABLE_EIRINI}
  autoscaler:
    enabled: ${AUTOSCALER}
  ${INGRESS_BLOCK}

high_availability: ${HA}
EOF

# TODO add functionality
# if [ "${services}" == "lb" ]; then
# fi
