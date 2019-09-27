#!/bin/bash

. scripts/include/common.sh
. .envrc

set -exuo pipefail

export DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

kubectl delete pod cats -n scf || true 

export DEFAULT_STACK="${DEFAULT_STACK:-cflinuxfs3}"
export CATS_REPO="${CATS_REPO:-https://github.com/cloudfoundry/cf-acceptance-tests}"

pod_definition=$(erb ../kube/cats/pod.yaml.erb)
cat <<EOF
Will create this pod (if you see empty values, make sure you defined all the needed env variables):

${pod_definition}
EOF

kubectl apply -n scf -f <(echo "${pod_definition}")

container_status() {
    kubectl get --output=json -n scf pod "$1" \
        | jq '.status.containerStatuses[0].state.terminated.exitCode | tonumber' 2>/dev/null
}

while [[ -z $(container_status "cats") ]]; do
    kubectl attach -n scf "cats" ||:
done

mkdir -p artifacts
kubectl logs -f cats -n scf > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_cats.log
status="$(container_status "cats")"
kubectl delete pod -n scf cats
exit "$status"
