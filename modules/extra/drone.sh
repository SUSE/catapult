#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


info "Deploying drone from the helm charts - be sure to have deployed gitea first, as drone will use gitea to run your pipeline against"
domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

warn "!!!! It needs a gitea deployment first !!!!!"

info "If you didn't already: "
info "1. Go to http://${domain}:30080/user/settings/applications"
info "2. Create a new application, name it drone, redirect uri is: http://${domain}:32011/login"
info "Use those secrets for DRONE_CLIENT_ID and DRONE_CLIENT_SECRET"


helm delete --purge drone || true

kubectl delete secret -n drone --all || true
kubectl delete pvc -n drone --all || true

helm install --name drone --namespace drone stable/drone

kubectl create secret generic drone-server-secrets \
      --namespace=drone \
      --from-literal=clientSecret="${DRONE_CLIENT_SECRET}"

helm upgrade drone \
  --reuse-values --set 'service.type=LoadBalancer' \
  --set "service.nodePort=32011" --set 'sourceControl.provider=gitea' \
  --set "sourceControl.gitea.clientID=${DRONE_CLIENT_ID}" \
  --set "sourceControl.gitea.server=http://${domain}:30080" \
  --set 'sourceControl.secret=drone-server-secrets' --set "server.host=${domain}:32011" \
  stable/drone

bash "$ROOT_DIR"/include/wait_ns.sh drone

echo "Drone endpoint is: http://${domain}:32011"