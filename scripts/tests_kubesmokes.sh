#!/bin/bash

. scripts/include/common.sh
. .envrc

set -exuo pipefail

export DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

kubectl delete pod smokes -n scf || true 

export SMOKES_REPO="${SMOKES_REPO:-https://github.com/cloudfoundry/cf-smoke-tests}"

pod_definition=$(erb ../kube/smokes/pod.yaml.erb)
cat <<EOF
Will create this pod (if you see empty values, make sure you defined all the needed env variables):

${pod_definition}
EOF

kubectl apply -n scf -f <(echo "${pod_definition}")

container_status() {
    kubectl get --output=json -n scf pod "$1" \
        | jq '.status.containerStatuses[0].state.terminated.exitCode | tonumber' 2>/dev/null
}

while [[ -z $(container_status "smokes") ]]; do
    kubectl attach -n scf "smokes" ||:
done

mkdir -p artifacts
kubectl logs -f smokes -n scf > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_smokes.log
status="$(container_status "smokes")"
kubectl delete pod -n scf smokes
exit "$status"
