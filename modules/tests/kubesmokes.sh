#!/bin/bash

. ../../include/common.sh
. .envrc

set -euo pipefail

export DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
DEPLOYED_CHART=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["chart"]')

echo
echo "@@@@@@@@@"
echo "Running Smoke tests on deployed chart $DEPLOYED_CHART"
echo "@@@@@@@@@"
echo

kubectl create namespace catapult || true
kubectl delete pod smokes -n catapult || true

export SMOKES_REPO="${SMOKES_REPO:-https://github.com/cloudfoundry/cf-smoke-tests}"

pod_definition=$(erb "$ROOT_DIR"/kube/smokes/pod.yaml.erb)
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
while [[ -z $(container_status "smokes") ]]; do
    kubectl attach -n catapult "smokes" ||:
done

set +e
mkdir -p artifacts
kubectl logs -f smokes -n catapult > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_smokes.log
status="$(container_status "smokes")"
kubectl delete pod -n catapult smokes
exit "$status"
