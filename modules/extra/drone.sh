#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


info "Deploying drone from the helm charts - be sure to have deployed gitea first, as drone will use gitea to run your pipeline against"
domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
plugin_secret="$(openssl rand -hex 16)"
warn "!!!! It needs a gitea deployment first !!!!!"

info "If you didn't already: "
info "1. Go to http://${domain}:30080/user/settings/applications"
info "2. Create a new application, name it drone, redirect uri is: http://${domain}:32011/login"
info "Use those secrets for DRONE_CLIENT_ID and DRONE_CLIENT_SECRET"


helm delete --purge drone || true

kubectl delete secret -n drone --all || true
kubectl delete pvc -n drone --all || true
kubectl delete namespace drone || true
kubectl delete svc -n drone --all || true
kubectl delete pod -n drone --all || true
kubectl create namespace drone
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: starlark
  namespace: drone
  labels:
    app: starlark
spec:
  containers:
    - name: starlark
      image: drone/drone-convert-starlark
      env:
      - name: DRONE_SECRET
        value: "$plugin_secret"
      - name: DRONE_DEBUG
        value: "true"
---
apiVersion: v1
kind: Service
metadata:
  name: starlark
  namespace: drone
spec:
  selector:
    app: starlark
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000

EOF

starlark_svc=$(kubectl get svc -n drone starlark -o jsonpath="{.spec.clusterIP}")

helm install --name drone --namespace drone stable/drone

kubectl create secret generic drone-server-secrets \
      --namespace=drone \
      --from-literal=clientSecret="${DRONE_CLIENT_SECRET}"

helm upgrade drone \
  --reuse-values --set 'service.type=LoadBalancer' \
  --set "service.nodePort=32011" --set 'sourceControl.provider=gitea' \
  --set "sourceControl.gitea.clientID=${DRONE_CLIENT_ID}" \
  --set "sourceControl.gitea.server=http://${domain}:30080" \
  --set "server.env.DRONE_CONVERT_PLUGIN_ENDPOINT=http://${starlark_svc}:3000" \
  --set "server.env.DRONE_CONVERT_PLUGIN_SECRET=$plugin_secret" \
  --set 'sourceControl.secret=drone-server-secrets' --set "server.host=${domain}:32011" \
  stable/drone

bash "$ROOT_DIR"/include/wait_ns.sh drone

if [ "$BACKEND" == "ekcp" ]; then
  PODNAME=$(kubectl get pods -n drone -l app=drone -o jsonpath="{.items[0].metadata.name}")
  info "Inside the cluster, drone is reachable at http://${domain}:32011"
  info "To access it from your local machine, run:"
  info "for http access (to local http://127.0.0.1:32011): kubectl port-forward --namespace drone $PODNAME 32011:80"
else
  info "Drone endpoint is: http://${domain}:32011"
fi
