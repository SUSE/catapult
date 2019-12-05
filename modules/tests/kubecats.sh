#!/bin/bash

. ../../include/common.sh
. .envrc


export DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
DEPLOYED_CHART=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["chart"]')

info
info "@@@@@@@@@"
info "Running CATs on deployed chart $DEPLOYED_CHART"
info "@@@@@@@@@"
info

kubectl create namespace catapult || true
kubectl delete pod cats -n catapult || true

export DEFAULT_STACK="${DEFAULT_STACK:-cflinuxfs3}"
export CATS_REPO="${CATS_REPO:-https://github.com/cloudfoundry/cf-acceptance-tests}"

pod_definition=$(erb "$ROOT_DIR"/kube/cats/pod.yaml.erb)
cat <<EOF
Will create this pod (if you see empty values, make sure you defined all the needed env variables):

${pod_definition}
EOF

kubectl apply -n catapult -f <(echo "${pod_definition}")

container_status() {
    kubectl get --output=json -n catapult pod "$1" \
        | jq '.status.containerStatuses[0].state.terminated.exitCode | tonumber' 2>/dev/null
}

bash ../include/wait_ns.sh catapult
while [[ -z $(container_status "cats") ]]; do
    kubectl attach -n catapult "cats" ||:
done

set +e
mkdir -p artifacts
kubectl logs -f cats -n catapult > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_cats.log
status="$(container_status "cats")"
kubectl delete pod -n catapult cats
exit "$status"
