#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
export DOMAIN
DEPLOYED_CHART=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["chart"]')

info
info "@@@@@@@@@"
info "Running CATs on deployed chart $DEPLOYED_CHART"
info "@@@@@@@@@"
info

kubectl create namespace catapult || true
kubectl delete pod cats -n catapult || true

if [ "${DEFAULT_STACK}" = "from_chart" ]; then
    DEFAULT_STACK=$(helm inspect helm/cf/ | grep DEFAULT_STACK | sed  's~DEFAULT_STACK:~~g' | sed 's~"~~g' | sed 's~\s~~g')
    export DEFAULT_STACK
fi

export CATS_REPO=$CATS_REPO
pod_definition=$(erb "$ROOT_DIR"/kube/cats/pod.yaml.erb)
cat <<EOF
Will create this pod (if you see empty values, make sure you defined all the needed env variables):

${pod_definition}
EOF

kubectl apply -n catapult -f <(echo "${pod_definition}")
wait_ns catapult

wait_container_attached "catapult" "cats"

set +e
mkdir -p artifacts
kubectl logs -f cats -n catapult > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_cats.log
status="$(container_status "catapult" "cats")"
kubectl delete pod -n catapult cats
exit "$status"
