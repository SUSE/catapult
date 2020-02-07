#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


export DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
DEPLOYED_CHART=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["chart"]')

info
info "@@@@@@@@@"
info "Running Smoke tests on deployed chart $DEPLOYED_CHART"
info "@@@@@@@@@"
info

kubectl create namespace catapult || true
kubectl delete pod smokes -n catapult || true

export SMOKES_REPO=$SMOKES_REPO
pod_definition=$(erb "$ROOT_DIR"/kube/smokes/pod.yaml.erb)
cat <<EOF
Will create this pod (if you see empty values, make sure you defined all the needed env variables):

${pod_definition}
EOF

kubectl apply -n catapult -f <(echo "${pod_definition}")
wait_ns catapult

wait_container_attached "catapult" "smokes"

set +e
mkdir -p artifacts
kubectl logs -f smokes -n catapult > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_smokes.log
status="$(container_status "catapult" "smokes")"
kubectl delete pod -n catapult smokes
exit "$status"
