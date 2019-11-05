#!/bin/bash

set -e

. ../../include/common.sh
. .envrc

LOCAL_ACCESS=${LOCAL_ACCESS:-true}

info "Deploying concourse from the helm charts"
domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
aux_external_ips=($(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address'))
external_ips+="\"$public_ip\""
for (( i=0; i < ${#aux_external_ips[@]}; i++ )); do
external_ips+=", \"${aux_external_ips[$i]}\""
done
set -x

if [ "${LOCAL_ACCESS}" == "true" ]; then
    domain="127.0.0.1:8080"
fi

helm delete --purge catapult-concourse || true
kubectl delete pvc -l app=catapult-concourse-worker || true
kubectl delete namespace catapult-concourse-main  || true

cat > concourse-values.yml <<EOF
concourse:
  web:
    externalUrl: http://${domain}
    bindPort: 80
    service:
      type: LoadBalancer
      loadBalancerIP: ${public_ip}
EOF

helm install --name catapult-concourse -f concourse-values.yml \
   stable/concourse

bash "$ROOT_DIR"/include/wait_ns.sh default

if [ "${LOCAL_ACCESS}" == "true" ]; then

    export POD_NAME=$(kubectl get pods --namespace default -l "app=catapult-concourse-web" -o jsonpath="{.items[0].metadata.name}")

    info "After exiting, if you want to access Concourse, do: 'kubectl port-forward --namespace default $POD_NAME 8080:80'"
    ok "All done"
    info "Now you can visit http://${domain} to use Concourse and login with test:test,"
    info "or use the cli and login with: fly -t local login -c http://$domain/"

    kubectl port-forward --namespace default $POD_NAME 8080:80
fi