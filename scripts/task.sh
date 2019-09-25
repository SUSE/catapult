#!/bin/bash

. scripts/include/common.sh
. .envrc

set -exuo pipefail

kubectl create namespace bkindwscf || true
kubectl delete -f ../kube/task.yaml || true
kubectl create -f ../kube/task.yaml 

bash ../scripts/wait_ns.sh bkindwscf

kubectl cp ../build$CLUSTER_NAME bkindwscf/task:/bkindwscf/
kubectl cp $TASK_SCRIPT bkindwscf/task:/bkindwscf/build$CLUSTER_NAME/

kubectl exec -ti -n bkindwscf task -- bash -c "CLUSTER_NAME=$CLUSTER_NAME make buildir login"

exit $(kubectl exec -ti task -n bkindwscf /bkindwscf/build$CLUSTER_NAME/$(basename $TASK_SCRIPT))
