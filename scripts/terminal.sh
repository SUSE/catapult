#!/bin/bash

. scripts/include/common.sh
. .envrc

set -euo pipefail

kubectl create namespace catapult || true
kubectl create -f ../kube/task.yaml || true

bash ../scripts/wait_ns.sh catapult

kubectl cp ../build$CLUSTER_NAME catapult/task:/catapult/
kubectl exec -ti -n catapult task -- /bin/bash -c "CLUSTER_NAME=$CLUSTER_NAME make buildir login" || true

echo "source build$CLUSTER_NAME/.envrc" > .bashrc
kubectl cp .bashrc catapult/task:/catapult/
rm -rf .bashrc

echo
echo "@@@@@@@@@@@@@@"
echo "Executing into the persistent pod"
echo "You can already use 'cf' and 'kubectl'"
echo "Note: After you are done, you need to remove it explictly with: kubectl delete pod -n catapult task"
echo "@@@@@@@@@@@@@@"
echo

exec kubectl exec -ti task -n catapult -- /bin/bash -l -c "source build$CLUSTER_NAME/.envrc && /bin/bash"