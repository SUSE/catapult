#!/bin/bash

. ../../include/common.sh
. .envrc

set -euo pipefail

kubectl create namespace catapult || true
kubectl create -f "$ROOT_DIR"/kube/task.yaml || true

bash "$ROOT_DIR"/include/wait_ns.sh catapult

kubectl cp "$ROOT_DIR"/build$CLUSTER_NAME catapult/task:/catapult/
kubectl cp "$TASK_SCRIPT" catapult/task:/catapult/build$CLUSTER_NAME/

kubectl exec -ti -n catapult task -- bash -c "CLUSTER_NAME=$CLUSTER_NAME make buildir login"


echo
echo "@@@@@@@@@@@@@@"
echo "Running $TASK_SCRIPT in /catapult/build$CLUSTER_NAME inside the task pod (in catapult namespace)"
echo "@@@@@@@@@@@@@@"
echo

kubectl exec -ti task -n catapult -- /bin/bash -l -c "source build$CLUSTER_NAME/.envrc && /catapult/build$CLUSTER_NAME/$(basename $TASK_SCRIPT)"
status=$?
exit $status
