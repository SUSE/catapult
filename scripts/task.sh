#!/bin/bash

. scripts/include/common.sh
. .envrc

set -euo pipefail

kubectl create namespace bkindwscf || true
kubectl create -f ../kube/task.yaml || true

bash ../scripts/wait_ns.sh bkindwscf

kubectl cp ../build$CLUSTER_NAME bkindwscf/task:/bkindwscf/
kubectl cp $TASK_SCRIPT bkindwscf/task:/bkindwscf/build$CLUSTER_NAME/

kubectl exec -ti -n bkindwscf task -- bash -c "CLUSTER_NAME=$CLUSTER_NAME make buildir login"


echo
echo "@@@@@@@@@@@@@@"
echo "Running $TASK_SCRIPT in /bkindwscf/build$CLUSTER_NAME inside the task pod (in bkindwscf namespace)"
echo "@@@@@@@@@@@@@@"
echo

kubectl exec -ti task -n bkindwscf -- /bin/bash -l -c "source build$CLUSTER_NAME/.envrc && /bkindwscf/build$CLUSTER_NAME/$(basename $TASK_SCRIPT)"
status=$?
exit $status