#!/bin/bash

. ../../include/common.sh
. .envrc

kubectl create namespace catapult || true
kubectl create -f "$ROOT_DIR"/kube/dind.yaml -n catapult || true
kubectl create -f "$ROOT_DIR"/kube/task.yaml -n catapult || true

wait_ns catapult

kubectl cp "$ROOT_DIR"/build$CLUSTER_NAME catapult/task:/catapult/
kubectl cp "$TASK_SCRIPT" catapult/task:/catapult/build$CLUSTER_NAME/

kubectl exec -ti -n catapult task -- bash -c "CLUSTER_NAME=$CLUSTER_NAME make buildir scf-login" || true


info
info "@@@@@@@@@@@@@@"
info "Running $TASK_SCRIPT in /catapult/build$CLUSTER_NAME inside the task pod (in catapult namespace)"
info "@@@@@@@@@@@@@@"
info

kubectl exec -ti task -n catapult -- /bin/bash -l -c "pushd build$CLUSTER_NAME || exit && source .envrc && popd && /catapult/build$CLUSTER_NAME/$(basename $TASK_SCRIPT)"
status=$?
exit $status
