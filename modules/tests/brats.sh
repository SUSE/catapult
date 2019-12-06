#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
DEPLOYED_CHART=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["chart"]')

info
info "@@@@@@@@@"
info "Running BRATs on deployed chart $DEPLOYED_CHART"
info "@@@@@@@@@"
info

kubectl create namespace catapult || true
kubectl delete pod brats -n catapult || true
kubectl create -f "$ROOT_DIR"/kube/dind.yaml -n catapult || true


pod_definition=$(erb "$ROOT_DIR"/kube/brats/pod.yaml.erb)
redacted_pod_definition=$(echo -e "$pod_definition" | sed -e '/COMPOSER/,+1d')
cat <<EOF
Will create this pod (if you see empty values, make sure you defined all the needed env variables) Note: the COMPOSER_GITHUB_OAUTH_TOKEN is redacted:

${redacted_pod_definition}
EOF

kubectl apply -n catapult -f <(echo "${pod_definition}")

container_status() {
    kubectl get --output=json -n catapult pod "$1" \
        | jq '.status.containerStatuses[0].state.terminated.exitCode | tonumber' 2>/dev/null
}

bash ../include/wait_ns.sh catapult
while [[ -z $(container_status "brats") ]]; do
    kubectl attach -n catapult "brats" ||:
done

set +e
mkdir -p artifacts
kubectl logs -f brats -n catapult > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_brats.log
status="$(container_status "brats")"
kubectl delete pod -n catapult brats
exit "$status"
