#!/bin/bash

. scripts/include/common.sh
. .envrc

set -euo pipefail

kubectl create namespace bkindwscf || true
kubectl delete -f ../kube/task.yaml || true
kubectl create -f ../kube/task.yaml 

bash ../scripts/wait_ns.sh bkindwscf

kubectl cp ../build$CLUSTER_NAME bkindwscf/task:/bkindwscf/
kubectl exec -ti -n bkindwscf task -- /bin/bash -c "CLUSTER_NAME=$CLUSTER_NAME make buildir login" || true

echo
echo "@@@@@@@@@@@@@@"
echo "Run: source build$CLUSTER_NAME/.envrc"
echo "@@@@@@@@@@@@@@"
echo
exec kubectl exec -ti task -n bkindwscf -- /bin/bash
