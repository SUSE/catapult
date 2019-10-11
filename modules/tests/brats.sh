#!/bin/bash

. ../../include/common.sh
. .envrc

set -euo pipefail

DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
DEPLOYED_CHART=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["chart"]')

echo
echo "@@@@@@@@@"
echo "Running BRATs on deployed chart $DEPLOYED_CHART"
echo "@@@@@@@@@"
echo

kubectl create namespace catapult || true
kubectl delete pod brats -n catapult || true

export BRATS_CF_HOST="${BRATS_CF_HOST:-api.$DOMAIN}"
export PROXY_HOST="${PROXY_HOST:-${public_ip}}"
export PROXY_SCHEME="${PROXY_SCHEME:-http}"
export BRATS_CF_USERNAME="${BRATS_CF_USERNAME:-admin}"
export BRATS_CF_PASSWORD="${BRATS_CF_PASSWORD:-$CLUSTER_PASSWORD}"
export PROXY_PORT="${PROXY_PORT:-9002}"
export PROXY_USERNAME="${PROXY_USERNAME:-username}"
export PROXY_PASSWORD="${PROXY_PASSWORD:-password}"
export BRATS_TEST_SUITE="${BRATS_TEST_SUITE:-brats}"
export CF_STACK="${CF_STACK:-sle15}"
export GINKGO_ATTEMPTS="${GINKGO_ATTEMPTS:-3}"

export BRATS_BUILDPACK="${BRATS_BUILDPACK}"
export BRATS_BUILDPACK_URL="${BRATS_BUILDPACK_URL}"
export BRATS_BUILDPACK_VERSION="${BRATS_BUILDPACK_VERSION}"

pod_definition=$(erb "$ROOT_DIR"/kube/brats/pod.yaml.erb)
cat <<EOF
Will create this pod (if you see empty values, make sure you defined all the needed env variables):

${pod_definition}
EOF

kubectl apply -n catapult -f <(echo "${pod_definition}")

container_status() {
    kubectl get --output=json -n catapult pod "$1" \
        | jq '.status.containerStatuses[0].state.terminated.exitCode | tonumber' 2>/dev/null
}

bash ../scripts/wait_ns.sh catapult
while [[ -z $(container_status "brats") ]]; do
    kubectl attach -n catapult "brats" ||:
done

set +e
mkdir -p artifacts
kubectl logs -f brats -n catapult > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_brats.log
status="$(container_status "brats")"
kubectl delete pod -n catapult brats
exit "$status"
