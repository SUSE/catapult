#!/bin/bash

. scripts/include/common.sh
. .envrc

set -exuo pipefail

DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')

if kubectl get pods -n scf 2>/dev/null | grep -qi brats; then
    kubectl delete pod brats -n scf
fi

export BRATS_CF_HOST="${BRATS_CF_HOST:-api.$DOMAIN}"
export PROXY_HOST="${PROXY_HOST:-${public_ip}}"
export PROXY_SCHEME="${PROXY_SCHEME:-http}"
export BRATS_CF_USERNAME="${BRATS_CF_USERNAME:-admin}"
export BRATS_CF_PASSWORD="${BRATS_CF_PASSWORD:-$CLUSTER_PASSWORD}"
export PROXY_PORT="${PROXY_PORT:-9002}"
export PROXY_USERNAME="${PROXY_USERNAME:-username}"
export PROXY_PASSWORD="${PROXY_PASSWORD:-password}"
export BRATS_TEST_SUITE=brats
export CF_STACK="${CF_STACK:-sle15}"

pod_definition=$(erb ../kube/brats/pod.yaml.erb)
cat <<EOF
Will create this pod (if you see empty values, make sure you defined all the needed env variables):

${pod_definition}
EOF

kubectl apply -n scf -f <(echo "${pod_definition}")

container_status() {
    kubectl get --output=json -n scf pod "$1" \
        | jq '.status.containerStatuses[0].state.terminated.exitCode | tonumber' 2>/dev/null
}

while [[ -z $(container_status "brats") ]]; do
    kubectl attach -n scf "brats" ||:
done

mkdir -p artifacts
kubectl logs -f brats -n scf > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_brats.log
kubectl delete pod -n scf brats
exit "$(container_status "brats")"
